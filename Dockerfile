FROM alpine as builder

RUN apk --no-cache add g++ boost-dev git make boost
RUN git clone --depth 1 https://github.com/VROOM-Project/vroom.git
RUN mkdir -p /vroom/bin
RUN cd /vroom/src && make
RUN strip /vroom/bin/vroom

FROM alpine

COPY --from=builder /vroom/bin/* /usr/local/bin/

RUN apk --no-cache add boost-system nodejs-npm nodejs git && \
	git clone --depth 1 https://github.com/VROOM-Project/vroom-express.git && \
	adduser -D vroom && \
	mkfifo -m 600 /vroom-express/logpipe && \
	chown vroom /vroom-express/logpipe && \
	ln -sf /vroom-express/logpipe /vroom-express/access.log && \
	ln -sf /vroom-express/logpipe /vroom-express/error.log && \
	sed -ri "s/(osrm_address:).*,/\1 \"osrm-backend\",/" /vroom-express/src/index.js && \
	apk del git && \
	cd /vroom-express && \
	npm install

EXPOSE 3000

COPY vroom-express.sh /usr/local/bin/vroom-express.sh
CMD ["vroom-express.sh"]

USER vroom
