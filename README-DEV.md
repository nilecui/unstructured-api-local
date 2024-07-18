./script/docker-build.sh

```shell
[root@localhost unstructured-api]# docker images | grep fami
pipeline-family-general-dev                                  latest                       bd44932f014e   5 minutes ago   9.4GB

docker run -p 8070:8000 -d --rm --name unstructured-api pipeline-family-general-dev:latest

```

# DOCKERFILE添加代理：
ENV http_proxy=http://192.168.12.82:10909
ENV https_proxy=http://192.168.12.82:10909
ENV HTTP_PROXY=http://192.168.12.82:10909
ENV HTTPS_PROXY=http://192.168.12.82:10909

# 修改代码

```python
app = FastAPI(
    title="Unstructured Pipeline API",
    summary="Partition documents with the Unstructured library",
    version="0.0.73",
    docs_url="/general/docs",
    openapi_url="/general/openapi.json",
    servers=[
        {
            "url": "https://api.unstructured.io",
            "description": "Hosted API",
            "x-speakeasy-server-id": "prod",
        },
        {
            "url": "http://192.168.12.180:8070", # 修改为服务器地址
            "description": "Development server",
            "x-speakeasy-server-id": "local",
        },
    ],
```

# build docker images

Dockerfile

```yaml
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

```




```shell
[root@localhost unstructured-api]# ./scripts/docker-build.sh
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 2.01kB done
#1 DONE 0.0s

#2 resolve image config for docker-image://docker.io/docker/dockerfile:experimental
#2 ...

#3 [auth] docker/dockerfile:pull token for registry-1.docker.io
#3 DONE 0.0s

#2 resolve image config for docker-image://docker.io/docker/dockerfile:experimental
#2 DONE 5.3s

#4 docker-image://docker.io/docker/dockerfile:experimental@sha256:600e5c62eedff338b3f7a0850beb7c05866e0ef27b2d2e8c02aa468e78496ff5
#4 CACHED

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 2.01kB done
#1 DONE 0.0s

#5 [internal] load build definition from Dockerfile
#5 DONE 0.0s

#6 [internal] load .dockerignore
#6 transferring context: 2B done
#6 DONE 0.0s

#7 [internal] load metadata for quay.io/unstructured-io/base-images:wolfi-base-e48da6b@sha256:8ad3479e5dc87a86e4794350cca6385c01c6d110902c5b292d1a62e231be711b
#7 DONE 1.2s

```

成功：
```shell
#19 [code 5/5] COPY --chown=notebook-user:notebook-user scripts/app-start.sh scripts/app-start.sh
#19 DONE 0.2s

#20 exporting to image
#20 exporting layers
#20 exporting layers 48.2s done
#20 preparing layers for inline cache done
#20 writing image sha256:b264ed84613fb7c3d6f1ab46fec2d7b0b11941b48bd4cc8d0c90c38e0ec676d0 done
#20 naming to docker.io/library/pipeline-family-general-dev done
#20 DONE 48.2s


[root@localhost unstructured-api]# docker images | grep pipeline-family-general-dev
pipeline-family-general-dev                                  latest                       b264ed84613f   About a minute ago   9.4GB


```


#报错

##1.huggingface

```shell
urllib3.exceptions.MaxRetryError: HTTPSConnectionPool(host='huggingface.co', port=443): Max retries exceeded with url: /microsoft/table-transformer-structure-recognition/resolve/main/config.json (Caused by NewConnectionError('<urllib3.connection.HTTPSConnection object at 0x7ff64c102fd0>: Failed to establish a new connection: [Errno 101] Network is unreachable'))

During handling of the above exception, another exception occurred:


```

解决方法：
- 科学上网