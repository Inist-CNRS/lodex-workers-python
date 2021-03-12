FROM node:12-alpine AS build
WORKDIR /app
# see .dockerignore to know all copied files
COPY . /app/
RUN mkdir -p /app/public && \
    apk add --no-cache --virtual .build-deps make gcc g++ python bash git openssh && \
    npm install --production && \
	npm cache clean --force && \
	npm prune --production && \
	apk del --no-cache .build-deps && \
	cd ./local && \
	npm install && \
    npm run build && \
	npm cache clean --force && \
	npm prune --production
FROM node:12-alpine AS release
COPY --from=build /app /app
WORKDIR /app
COPY config.json crontab.js generate-dotenv.js gitsync gitsyncdir chmod-all chmod-one docker-entrypoint.sh public /app/
# To be compilant with
# - Debian/Ubuntu container (and so with ezmaster-webdav)
# - ezmaster see https://github.com/Inist-CNRS/ezmaster
RUN apk add --update-cache --no-cache su-exec bash git openssh build-base python3 python3-dev py3-pip libgfortran lapack-dev openblas-dev && \
	echo '{ \
      "httpPort": 31976, \
      "configPath": "/app/config.json", \
      "dataPath": "/app/public" \
    }' > /etc/ezmaster.json && \
    sed -i -e "s/daemon:x:2:2/daemon:x:1:1/" /etc/passwd && \
    sed -i -e "s/daemon:x:2:/daemon:x:1:/" /etc/group && \
    sed -i -e "s/bin:x:1:1/bin:x:2:2/" /etc/passwd && \
    sed -i -e "s/bin:x:1:/bin:x:2:/" /etc/group && \
	pip3 install --upgrade pip
ENTRYPOINT [ "/app/docker-entrypoint.sh" ]
CMD [ "npm", "start" ]
