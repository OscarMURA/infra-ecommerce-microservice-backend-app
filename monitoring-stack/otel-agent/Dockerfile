# Imagen minimalista con el agente OpenTelemetry
FROM busybox:1.36

# Descargar el agente de OpenTelemetry
ARG OTEL_VERSION=1.32.0
ADD https://repo1.maven.org/maven2/io/opentelemetry/javaagent/opentelemetry-javaagent/${OTEL_VERSION}/opentelemetry-javaagent-${OTEL_VERSION}.jar /otel/opentelemetry-javaagent.jar

# Hacer el archivo legible
RUN chmod 644 /otel/opentelemetry-javaagent.jar

# Comando por defecto - solo copiar el agente
CMD ["cp", "/otel/opentelemetry-javaagent.jar", "/agent/opentelemetry-javaagent.jar"]
