
ARG VERSION_PIMO=v1.19.0

FROM cgifr/pimo:${VERSION_PIMO} AS pimo

FROM jauderho/dsq:v0.23.0 as dsq

FROM mcr.microsoft.com/devcontainers/javascript-node:16

# Configuring Elm version
ARG ELM_VERSION=latest-0.19.1
ARG ELM_TEST_VERSION=latest-0.19.1
ARG ELM_FORMAT_VERSION=latest-0.19.1



# This Dockerfile adds a non-root user with sudo access. Update the “remoteUser” property in
# devcontainer.json to use it. More info: https://aka.ms/vscode-remote/containers/non-root-user.
ARG USERNAME=node
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install elm, elm-test and elm-format
RUN export DEBIAN_FRONTEND=noninteractive \
    && sudo -u ${USERNAME} npm install --global \
    elm@${ELM_VERSION} \
    elm-test@${ELM_TEST_VERSION} \
    elm-format@${ELM_FORMAT_VERSION} \
    #
    # [Optional] Update UID/GID if needed
    && if [ "$USER_GID" != "1000" ] || [ "$USER_UID" != "1000" ]; then \
        groupmod --gid $USER_GID $USERNAME \
        && usermod --uid $USER_UID --gid $USER_GID $USERNAME \
        && chown -R $USER_UID:$USER_GID /home/$USERNAME; \
    fi \
    # Create the elm cache directory where we can mount a volume. If we don't create it like this
    # it is auto created by docker on volume creation but with root as owner which makes it unusable.
    && mkdir /home/$USERNAME/.elm \
    && chown $USERNAME:$USERNAME /home/$USERNAME/.elm


ARG VERSION_SIGO=0.3.0
RUN wget -nv -O- https://github.com/CGI-FR/SIGO/releases/download/v${VERSION_SIGO}/SIGO_${VERSION_SIGO}_linux_amd64.tar.gz | sudo tar -xz -C /usr/bin sigo &&\
    chmod +x /usr/bin/sigo

COPY --from=dsq /usr/local/bin/dsq /usr/bin/dsq
COPY --from=pimo /usr/bin/pimo /usr/bin/pimo