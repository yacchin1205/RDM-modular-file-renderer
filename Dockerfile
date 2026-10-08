FROM python:3.13-slim AS build


RUN apt-get update

    # mfr dependencies
RUN apt-get install -y \
        git \
        make \
        gcc \
        build-essential \
        gfortran \
        libblas-dev \
        libevent-dev \
        libfreetype6-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff5-dev \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        gnupg2
RUN apt-get clean
RUN apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /code
WORKDIR /code

RUN pip install poetry==2.5.1 poetry-plugin-export==1.10.1

COPY pyproject.toml poetry.lock* /code/

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_CREATE=0

RUN poetry export --only main --without-hashes -o /tmp/requirements.txt \
    && pip wheel --no-deps --wheel-dir=/wheels -r /tmp/requirements.txt

# Copy the rest of the code over
COPY ./ /code/

RUN poetry build --format=wheel --output=/wheels

FROM python:3.13-slim

RUN usermod -d /home www-data \
    && chown www-data:www-data /home \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        r-base \
        # convert .step to jsc3d-compatible format
        freecad \
        # pspp dependencies
        pspp \
        # grab gosu for easy step-down from root
        gosu \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /code
COPY --from=build /wheels /wheels
RUN pip install --no-cache-dir --no-index --no-deps /wheels/*.whl \
    && pip check \
    && pip uninstall -y pip \
    && rm -rf /wheels
COPY --from=build /code /code

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_CREATE=0

ARG GIT_COMMIT=
ENV GIT_COMMIT=${GIT_COMMIT}

EXPOSE 7778

CMD ["gosu", "www-data", "invoke", "server"]
