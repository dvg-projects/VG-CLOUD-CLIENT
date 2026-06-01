[!Estado del Proyecto](https://shields.io)
> **Nota importante para Reclutadores:** Este proyecto se encuentra actualmente en **fase activa de desarrollo**. Algunas funcionalidades de la interfaz o del backend están siendo refactorizadas o implementadas gradualmente. El repositorio refleja mi flujo de trabajo real y diario.

# VG-CLOUD-MOBILE - Proyecto Flutter
# **CAPA DE CLIENTE**

Este repositorio contiene la aplicación móvil/escritorio desarrollada en Flutter que forma parte
de un ecosistema en la nube autoalojado para entornos domésticos de red local.

El presente proyecto está pensado para una app multiplataforma (Android/iOS/escritorio) que interactúa de forma segura con una
infraestructura privada desplegada sobre un servidor doméstico **Ubuntu Server**.

Para garantizar el funcionamiento esperado del mismo, este proyecto en su totalidad dispone de 3 capas perfectamente diferenciadas:

## Arquitectura de proyecto

1. **Capa de Cliente** (Presente repositorio): Aplicación basada en Flutter/Dart dotada de un sistema de usuarios
2. **Capa Intermedia (API Privada)**: Un backend robusto alojado localmente en mi servidor Ubuntu que gestiona de manera aislada la lógica de negocio y
las conexiones directas con los datos. La API interactúa y gestiona de manera directa y segura las conexiones a una base de datos PostgreSQL alojada en
el propio servidor.
3. **Capa de Servicios de Almacenamiento (Spring Boot)**: Un microservicio dedicado a la gestión de archivos y rutas dentro del
explorador de Linux (`/mnt/hdd/...`), optimizando el rendimiento de lectura/escritura de datos, además de ocuparse de las conversiones necesarias a los
ficheros con el fin de garantizar la compatibilidad total entre sistemas (iOS -> Android, viceversa...).

## Tecnologías y Estándares de Industria Utilizados

* **Flutter & Dart**: Desarrollo de interfaz fluida y desacoplada mediante patrones asíncronos. Para fomentar en todo momento la eficiencia y la experiencia
de usuario, se está dotando a dicha UI de una interfaz atractiva, basada en los exploradores de archivos convencionales.
* **Null Safety estricto**: Código blindado frente a excepciones de nulos mediante tipado seguro de Dart.
* **Seguridad & Git**: Implementación del paquete `flutter_dotenv` combinada con políticas estrictas de `.gitignore` para salvaguardar la privacidad de la red local.

## Instrucciones para Despliegue Local (PARTE DE CAPA CLIENTE)

Si deseas clonar el proyecto para auditar el código o realizar pruebas en tu propia red local, sigue estos pasos:
**NOTA** -> Será necesario que incluyas las dependencias necesarias relativas a `flutter_dotenv`.
Para más información: https://pub.dev/packages/flutter_dotenv

1. **Clonar el repositorio:**
   ```bash
   git clone <url_de_este_repositorio>
   ```
   NOTA -> Cópiala de la propia URL de tu navegador o de la sección derecha de esta misma página, en el botón "CODE"

2. **Configurar el entorno:**
   En la raíz del proyecto encontrarás un archivo plantilla llamado `.env.example`. Crea una copia de este archivo en la misma raíz y renómbrala exactamente a `.env`:
   ```bash
   # Duplica la plantilla para tu uso local
   cp .env.example .env
   ```

3. **Introducir variables:**
   Abre tu nuevo archivo `.env` y añade la URL de tu API local:
   ```text
   API_URL=http://tu_ip_local_o_localhost:puerto
   ```

4. **Ejecutar la aplicación:**
   ```bash
   flutter pub get
   flutter run
   ```

## Próximas Implementaciones (Roadmap)

Aquí hago listado de las funcionalidades implementadas y las pendientes por implementar, es necesario recalcar que incluso la propia lista podría cambiar, si surgen implementaciones no previstas:

- [x] Implementación de subida de ficheros (contando con el paquete Dart/Flutter `dio` para una retroalimentación lo más exacta posible del progreso de subida).
- [x] Implementación de borrado de ficheros.
- [x] Implementación de creación y borrado de directorios / carpetas (Individual y recursivamente, aplicándose también a los ficheros relativos).
- [x] Implementación de clasificado de ficheros en base a tipo.
- [x] Implementación de reproductores o visualizadores en base a tipo de ficheros (aún muy básicos, se necesita perfeccionar).
- [x] Migración completa a variables de entorno para seguridad de red local.
- [x] Arquitectura base de carpetas y desacoplamiento de capas.
- [x] Implementación de pantalla de Inicio de sesión y su lógica backend correspondiente.
- [x] Implementación de persistencia al inicio de sesión con `SharedPreferences`
- [ ] Implementación de mejoras en el registro de usuario, añadiendo criterios para las contraseñas (longitud, carácteres especiales...).
- [ ] Implementación de descarga de ficheros (siguiente paso natural habiendo implementado ya la subida de ficheros).
- [ ] Mejoras significativas en las pantallas de visualizado de ficheros multimedia (actualmente existe una versión muy primitiva).
- [ ] Implementación de sección informativa del estado del Cloud (memoria disponible, total, usada...).
- [ ] Implementación de sección de perfil de usuario (con ajustes menores).
- [ ] Implementación de pantalla de registro y su lógica backend correspondiente.
- [ ] Cobertura de pruebas unitarias para los controladores principales.
- [ ] Corrección de posibles errores y mejoras menores tanto en BackEnd como en GUI (front).

## :bug: :umbrella: Estado Actual y Bugs Conocidos :tool: :construction_worker:

Actualmente, el módulo de gestión de descargas se encuentra en desarrollo activo. Se han identificado las siguientes limitaciones temporales que están siendo subsanadas:

* **Descarga Recursiva:** Fallo puntual en la resolución de rutas al descargar directorios completos que contienen subcarpetas anidadas.
* **Rutas de Almacenamiento:** Comportamiento inconsistente en la asignación de rutas locales específicas bajo determinadas condiciones del sistema operativo.

*Nota: La aplicación es completamente estable, compila sin errores y la descarga de archivos individuales funciona al 100%.*