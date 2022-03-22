FROM node:alpine as base

RUN npm install -g selenium-side-runner urlencode-cli

FROM base
WORKDIR /app
COPY ["side_scripts", "runner.sh", "/app/"]
RUN chmod 700 runner.sh
ENTRYPOINT [ "./runner.sh" ]
