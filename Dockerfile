FROM nexcer/flutter-web

RUN git clone https://github.com/mushrifshahreyar/imagewebapp.git

RUN flutter channel beta

RUN flutter upgrade

RUN flutter config --enable-web

RUN flutter upgrade

RUN apt-get update

RUN apt-get install -y python python3-pip

RUN mv imagewebapp/ project1

WORKDIR /project1/

RUN flutter create .

RUN pip3 install -r Backend/requirements.txt

RUN chmod +x run.bash

CMD ./run.bash 

EXPOSE 8080


