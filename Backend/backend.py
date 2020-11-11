from flask import Flask, request, jsonify
from flask_mongoengine import MongoEngine
from datetime import datetime
import base64
import urllib.request
import json
from PIL import ExifTags, Image
from flask_cors import CORS
from PIL import TiffImagePlugin
import os

app = Flask(__name__)

app.config['MONGODB_SETTINGS'] = {
	'db': 'Gallery',
	'host': 'mongodb://mongodb:27017/imagedb',
	'port': 27017,
}

CORS(app=app)

db = MongoEngine()

db.init_app(app)

class Images(db.Document):
	
	_id = db.StringField(primary_key=True)
	name = db.StringField()
	image = db.StringField()
	metadata = db.DictField()
	
	def to_json(self):
		return {'name': self.name, 'image': self.image, 'metadata': self.metadata}

@app.route('/', methods=['GET'])
def hello():
	return jsonify({"hello" : "world"})

# Publishing the data in json format
@app.route('/get_image_data', methods=['GET'])
def get_image_data():
	images = Images.objects()
	if not images:
		return jsonify({'error': 'data not found'})
	else:
		images_json_array = []
		for image in images:
			image_json = {}
			image_json['name'] = image['name']
			image_json['id'] = image['_id']
			image_json['metadata'] = image['metadata']
			images_json_array.append(image_json)

		return jsonify(images_json_array)


# Inserting data into mongoDB
@app.route('/create_record', methods=['POST'])
def create_record():
	#two arguments 'url', 'name'
	record = json.loads(request.data)
	
	url = record['url']
	name = record['name']

	urllib.request.urlretrieve(url, name)
	my_image = Image.open(name)
	metadata = get_metadata(my_image)
	my_image.close()

	date_time = datetime.now()
	d = date_time.strftime("%m%d%y%h%m%s")
	imageDoc = Images(_id= str(d) ,name=name, image=url, metadata=dict(metadata))
	imageDoc.save()

	# Deleting the saved file
	if(os.path.exists(name)):
		os.remove(name)		
	
	return jsonify({'status': 'image uploaded'})

# Extracting metadata from image
def get_metadata(image):
	exifdata = image.getexif()
	metadata = {}
	for tag_id in exifdata:
	# get the tag name, instead of human unreadable tag id
		tag = ExifTags.TAGS.get(tag_id, tag_id)
		data = exifdata.get(tag_id)
		if isinstance(tag, str) and tag != 'MakerNote' and tag != 'UserComment':
			if isinstance(data, dict) or isinstance(data,bytes):
				data = str(data)
				metadata[tag] = data
   
			if(isinstance(data,TiffImagePlugin.IFDRational)):
				data = float(data)
				metadata[tag] = data
			if(isinstance(data,int) or isinstance(data,float) or isinstance(data,str)):
				metadata[tag] = data
			
			
	return metadata

# Fetching images using image id for displaying in homepage
@app.route('/getimage/<imageID>', methods=['GET'])
def post_imageURL(imageID):
	image = Images.objects(_id=imageID)
	base64Packet = base64.b64decode(image[0].image[23:])
	if not image:
		return jsonify({'err':'error'})
	else:
		return base64Packet

# Delete query {Future work}
@app.route('/delete_record', methods=['DELETE'])
def delete_record():
	#one argument 'id'
	record = json.loads(request.data)
	idQuery = record['id']
	images = Images.objects(_id=idQuery)
	if not images:
		return jsonify({'error': 'data not found'})
	else:
		for image in images:
			image.delete()
	return jsonify({'status': 'images deleted'})

@app.route('/query_records', methods=['POST'])
def query_records():
	
	query = json.loads(request.data)

	dict_query = {}
	for q in query:
		key, value = list(q.items())[0]
		dict_query[key] = value
		
	query = get_query(dict_query)
	print(query)
	images = Images.objects(__raw__=query)
	if not images:
		return jsonify({'error': 'data not found'})
	else:
		images_json_array = []
		for image in images:
			image_json = {}
			image_json['name'] = image['name']
			image_json['id'] = image['_id']
			image_json['metadata'] = image['metadata']
			images_json_array.append(image_json)

		return jsonify(images_json_array)

# Search query
def get_query(json_query):
	operator_to_syntax = {'==' : '$eq', '!=' : '$ne', '<' : '$lt', '>' : '$gt', '<=' : '$lte', '>=' : '$gte'}
	query = {}
	for attr, op in json_query.items():
		(operator, value) , =  op.items()
		if attr != 'Make':
			value = int(value)			
		query['metadata.' + attr] = {operator_to_syntax[operator] : value}
	return query

if __name__ == "__main__":
	app.run(debug=True, host='0.0.0.0')
	# app.run(debug=True)