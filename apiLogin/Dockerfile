# Etapa 1 — compila o jar
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn -B -DskipTests package

# Etapa 2 — imagem final, só com o runtime (bem menor que a de build)
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /build/target/*.jar app.jar

# O plano free do Render dá 512 MB de RAM. A JVM, sozinha, assume que pode usar
# bem mais que isso e o container morre por falta de memória; por isso limitamos a
# heap e usamos o coletor mais econômico. TieredStopAtLevel=1 encurta o tempo de
# boot, que importa aqui porque o serviço hiberna a cada 15 minutos parado.
ENV JAVA_OPTS="-XX:MaxRAMPercentage=65 -XX:+UseSerialGC -Xss512k -XX:TieredStopAtLevel=1"

# O Render injeta a porta em PORT; o application.properties já lê essa variável.
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
