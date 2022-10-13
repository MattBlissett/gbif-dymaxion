FROM python:3.7

COPY requirements.txt /root
RUN pip install --no-cache-dir -r /root/requirements.txt

COPY gbif-dymaxion.py /root

WORKDIR /usr/src/app
ENTRYPOINT [ "python", "/root/gbif-dymaxion.py" ]
