FROM maven:3.9-amazoncorretto-17 AS builder

RUN mkdir -p /opt/mop
WORKDIR /opt/mop
COPY . /opt/mop

RUN mvn clean install -DskipTests

FROM streamnative/sn-pulsar:3.1.1.2

RUN rm /pulsar/protocols/pulsar-protocol-handler-mqtt-*.nar

COPY --from=builder /opt/mop/mqtt-impl/target/pulsar-protocol-handler-mqtt-3.1.1.2.nar /pulsar/protocols/

# fix filesystem permission issues
RUN mkdir -p /pulsar/data && chown -R $USER:$USER /pulsar/data