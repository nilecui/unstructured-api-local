# syntax=docker/dockerfile:experimental
FROM quay.io/unstructured-io/base-images:wolfi-base-e48da6b@sha256:8ad3479e5dc87a86e4794350cca6385c01c6d110902c5b292d1a62e231be711b as base

# NOTE(crag): NB_USER ARG for mybinder.org compat:
#             https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html
ARG NB_USER=notebook-user
ARG NB_UID=1000
ARG PIP_VERSION
ARG PIPELINE_PACKAGE
ARG PYTHON_VERSION="3.11"

ENV http_proxy=http://192.168.12.82:10909
ENV https_proxy=http://192.168.12.82:10909
ENV HTTP_PROXY=http://192.168.12.82:10909
ENV HTTPS_PROXY=http://192.168.12.82:10909

# Set up environment
ENV PYTHON python${PYTHON_VERSION}
ENV PIP ${PYTHON} -m pip

WORKDIR ${HOME}
USER ${NB_USER}

ENV PYTHONPATH="${PYTHONPATH}:${HOME}"
ENV PATH="/home/${NB_USER}/.local/bin:${PATH}"

FROM base as python-deps
COPY --chown=${NB_USER}:${NB_USER} requirements/base.txt requirements-base.txt
RUN ${PIP} install pip==${PIP_VERSION}
RUN ${PIP} install --no-cache -r requirements-base.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

FROM python-deps as model-deps
RUN ${PYTHON} -c "import nltk; nltk.download('punkt')" && \
  ${PYTHON} -c "import nltk; nltk.download('averaged_perceptron_tagger')" && \
  ${PYTHON} -c "from unstructured.partition.model_init import initialize; initialize()"

FROM model-deps as code
COPY --chown=${NB_USER}:${NB_USER} CHANGELOG.md CHANGELOG.md
COPY --chown=${NB_USER}:${NB_USER} logger_config.yaml logger_config.yaml
COPY --chown=${NB_USER}:${NB_USER} prepline_${PIPELINE_PACKAGE}/ prepline_${PIPELINE_PACKAGE}/
COPY --chown=${NB_USER}:${NB_USER} exploration-notebooks exploration-notebooks
COPY --chown=${NB_USER}:${NB_USER} scripts/app-start.sh scripts/app-start.sh

ENTRYPOINT ["scripts/app-start.sh"]
# Expose a default port of 8000. Note: The EXPOSE instruction does not actually publish the port,
# but some tooling will inspect containers and perform work contingent on networking support declared.

EXPOSE 8000
