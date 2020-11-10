FROM nexcer/flutter-web

RUN git clone https://github.com/mushrifshahreyar/imageGallery.git

RUN flutter channel beta

RUN flutter upgrade

RUN flutter config --enable-web

RUN flutter upgrade

RUN mv imageGallery/ project1

RUN cd project1/

RUN flutter create project1

WORKDIR /project1/

CMD flutter run --release --web-port=8080

# RUN cd 
EXPOSE 8080

