FROM node:16.14.0-slim

COPY ./ ./

RUN npm install

ENV NODE_ENV production
ENV DATABASE postgres

EXPOSE 8080

CMD ["node", "app.js"]
