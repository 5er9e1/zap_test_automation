FROM node:alpine as base

RUN npm install -g selenium-side-runner urlencode-cli && apk update && apk upgrade && apk add --no-cache git openssh && echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config

FROM base
WORKDIR /app
COPY ["side_scripts", "runner.sh", "/app/"]
RUN chmod 700 runner.sh
ENTRYPOINT [ "./runner.sh" ]