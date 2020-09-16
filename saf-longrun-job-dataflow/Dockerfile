FROM gcr.io/dataflow-templates-base/python3-template-launcher-base

ARG WORKDIR=/dataflow/template
RUN mkdir -p ${WORKDIR}
WORKDIR ${WORKDIR}

COPY requirements.txt .
COPY saflongrunjobdataflow.py .

ENV FLEX_TEMPLATE_PYTHON_REQUIREMENTS_FILE="${WORKDIR}/requirements.txt"
ENV FLEX_TEMPLATE_PYTHON_PY_FILE="${WORKDIR}/saflongrunjobdataflow.py"

RUN pip install -U apache-beam[gcp]==2.23.0
RUN pip install -r "${WORKDIR}/requirements.txt"