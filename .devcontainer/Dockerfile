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
    apt-get -y --no-install-recommends install ca-certificates curl git unzip make gcc libc6-dev ripgrep fd-find xclip tree-sitter-cli && \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get -y install nodejs && \
    apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    npm install -g @fission-ai/openspec@latest

# Neovim
RUN cd /tmp && \
    curl -L -o nvim.tar.gz "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz" && \
    tar -xf nvim.tar.gz && \
    install nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim && \
    cp -R nvim-linux-x86_64/lib /usr/local/ && \
    cp -R nvim-linux-x86_64/share /usr/local/ && \
    rm -rf nvim-linux-x86_64 nvim.tar.gz  && \
    # mkdir -p /home/$USER_NAME/.config/nvim && \
    # curl -L -o /home/$USER_NAME/.config/nvim/init.lua https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/refs/heads/master/init.lua && \
    git clone https://github.com/LazyVim/starter /home/$USER_NAME/.config/nvim && \
    rm -rf /home/$USER_NAME/.config/nvim/.git && \
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config

# Lazygit
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*') && \
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
    tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit && \
    install /tmp/lazygit /usr/local/bin/lazygit && \
    rm /tmp/lazygit.tar.gz /tmp/lazygit

# [Optional] If your requirements rarely change, add them to the image.
