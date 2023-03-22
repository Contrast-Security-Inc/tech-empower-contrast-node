FROM node:16.14.0-slim

COPY ./ ./

RUN npm install

ENV NODE_ENV production
ENV DATABASE postgres

EXPOSE 8080

# Start Contrast Additions for node-agent-v4
COPY node-contrast.tgz node-contrast.tgz
COPY contrast_security.yaml /etc/contrast/contrast_security.yaml

ENV CONTRAST__API__ENABLE=false
ENV CONTRAST__ASSESS__ENABLE=true
ENV CONTRAST__PROTECT__ENABLE=false
ENV CONTRAST__AGENT__NODE__NATIVE_INPUT_ANALYSIS=true

RUN npm install ./node-contrast.tgz
# End Contrast Additions

CMD ["node", "-r", "@contrast/agent", "app.js"]

