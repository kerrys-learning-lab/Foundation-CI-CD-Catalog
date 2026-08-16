# ============================================================================
FROM docker.io/rockylinux/rockylinux:10.2-ubi AS base


# ----------------------------------------------------------------------------
# Global environment:
ENV INSTALL_DIR=/usr/local/install


ENV GLAB_VERSION=1.110.0
ENV GLAB_URL=https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_amd64.rpm


# ----------------------------------------------------------------------------
RUN dnf --quiet install --assumeyes epel-release  &&  \
    dnf config-manager --set-enabled crb  && \
    dnf --quiet install --assumeyes git  \
                                    ${GLAB_URL}  \
                                    hostname  \
                                    jq  \
                                    procps-ng  \
                                    tree  \
                                    which  \
                                    yq



# ============================================================================
FROM base AS bashunit


# ----------------------------------------------------------------------------
ENV BASHUNIT_VERSION=0.40.0
ENV BASHUNIT_URL=https://github.com/TypedDevs/bashunit/releases/download/${BASHUNIT_VERSION}/bashunit
RUN mkdir -p ${INSTALL_DIR}/bashunit-${BASHUNIT_VERSION}  && \
    curl  --location  \
          --fail  \
          --silent  \
          --show-error  \
          --remote-name  \
          --output-dir ${INSTALL_DIR}/bashunit-${BASHUNIT_VERSION}  \
          ${BASHUNIT_URL}  && \
    chmod a=rx ${INSTALL_DIR}/bashunit-${BASHUNIT_VERSION}/bashunit  && \
    ln -s ${INSTALL_DIR}/bashunit-${BASHUNIT_VERSION}/bashunit  /usr/local/bin/bashunit



# ============================================================================
FROM base AS mkdocs


RUN dnf install -y  mkdocs  \
                    mkdocs-material  \
                    python3-mkdocs-autorefs  \
                    python3-mkdocs-literate-nav  \
                    python3-mkdocs-material-extensions


# ============================================================================
FROM base AS glab
