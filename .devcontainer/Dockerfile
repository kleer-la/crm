FROM ruby:3.4.9

# ENV TZ=America/Argentina/Buenos_Aires
ARG USER_NAME
ARG USER_UID
ARG USER_GID

# You should only one of the following commands.
# If the user is already created in the image, we adjust the ids if necessary
# RUN if [ "$USER_GID" != "1000" ] || [ "$USER_UID" != "1000" ]; then groupmod --gid $USER_GID $USER_NAME && usermod --uid $USER_UID --gid $USER_GID $USER_NAME; fi
# If the user is NOT created in the image, we create it with the proper ids
RUN addgroup --gid $USER_GID $USER_NAME && adduser --disabled-password --gecos '' --uid $USER_UID --gid $USER_GID $USER_NAME

# [Optional] Uncomment this section to install additional OS packages.
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y update && \
    apt-get -y --no-install-recommends install ca-certificates curl git gh unzip make gcc libc6-dev fd-find xclip ffmpeg jq python3 python3-pip && \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get -y install nodejs && \
    apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    npm install -g @fission-ai/openspec@latest && \
    npm install -g open-code-ai@latest && \
    pip install --break-system-packages edge-tts

# Chrome for system tests (headless)
RUN curl -fsSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /tmp/chrome.deb && \
    apt-get -y update && \
    apt-get -y install /tmp/chrome.deb || apt-get -y --fix-broken install && \
    rm /tmp/chrome.deb && rm -rf /var/lib/apt/lists/*

# Docker CLI (uses host docker via mounted socket)
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | dd of=/usr/share/keyrings/docker-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bookworm stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get -y install docker-ce-cli && \
    rm -rf /var/lib/apt/lists/* && \
    (groupadd docker || true) && usermod -aG docker $USER_NAME

# [Optional] If your requirements rarely change, add them to the image.
