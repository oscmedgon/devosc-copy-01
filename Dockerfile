ARG ARCH=arm32v7

FROM $ARCH/node:16-buster as builder

ARG STACKBIT_API_KEY
ENV STACKBIT_API_KEY=$STACKBIT_API_KEY

WORKDIR /tmp/builder

COPY package.json .
COPY package-lock.json .

RUN npm install

RUN npx @stackbit/stackbit-pull --stackbit-pull-api-url=https://api.stackbit.com/pull/6117a59a63c0fc00bf1ab9ee

COPY . .
RUN ls -la
RUN npm run build

FROM $ARCH/nginx:alpine

COPY --chown=nginx --from=builder /tmp/builder/public /usr/share/blog

COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

RUN cat /etc/nginx/conf.d/default.conf

RUN ls -la /usr/share/blog

USER nginx

EXPOSE 8080

