# Homecenter Envíos — Aplicación web Java (Servlets + JSP + MySQL)

Sistema de realización y seguimiento de pedidos de Homecenter. Implementa el
modelo relacional de las evidencias GA6 (Cliente, Vendedor, Pedido, Factura,
Logística, Envío de pedido, Transportista, Incidencia y Notificación) con
operaciones de **inserción, consulta, actualización y eliminación** para cada tabla.

| Tecnología | Versión |
|---|---|
| Java (JDK) | 11 o superior (probado con JDK 25) |
| Servlets / JSP / JSTL | javax.servlet 3.1 · JSP 2.3 · JSTL 1.2 |
| Servidor | Apache Tomcat 8.5 (XAMPP) o Tomcat 9 |
| Base de datos | MySQL 8 o MariaDB 10.5+ |
| Construcción | Maven (incluido en NetBeans) |

---

## 1. Crear la base de datos

Ejecute el script completo en MySQL Workbench, phpMyAdmin o la consola:

```bash
mysql -u root -p < database/homecenter_db.sql
```

El script crea `homecenter_db` con datos de prueba. **Todas las cuentas de
ejemplo usan la contraseña `Homecenter2026*`:**

| Rol | Correo |
|---|---|
| Vendedor | andres.castillo@homecenter.com |
| Logística | jorge.ramirez@homecenter.com |
| Transportista | diego.martinez@homecenter.com |
| Cliente | maria.rojas@correo.com |

## 2. Configurar la conexión

Edite `src/main/resources/db.properties` con el usuario y la contraseña de su
servidor MySQL:

```properties
db.url=jdbc:mysql://localhost:3306/homecenter_db?useUnicode=true&characterEncoding=UTF-8&serverTimezone=America/Bogota
db.usuario=root
db.contrasena=
```

## 3. Compilar y desplegar

**Con NetBeans:** *File → Open Project* → seleccione la carpeta `homecenter-envios`
→ clic derecho → *Run* (elija Tomcat como servidor).

**Con Maven y Tomcat de XAMPP:**

```bash
mvn clean package
```

Copie `target/homecenter-envios.war` a `C:\xampp\tomcat\webapps\`, inicie Tomcat
desde el panel de XAMPP y abra <http://localhost:8080/homecenter-envios>.

---

## 4. Arquitectura (MVC)

```
src/main/java/co/homecenter/envios/
├── configuracion/   ConexionBD (JDBC) · InicializadorAplicacion (@WebListener)
├── modelo/          JavaBeans: Usuario (abstracta), Cliente, Vendedor, Logistica,
│                    Transportista, Pedido, Factura, EnvioPedido, Incidencia,
│                    Notificacion, Rol, UsuarioSesion
├── dao/             CrudDao<T> (interfaz) · BaseDao · un DAO por tabla ·
│                    AutenticacionDao · EstadisticaDao
├── controlador/     ServletBase · CrudServlet<T> (Template Method) · un servlet
│                    por módulo · LoginServlet · RegistroServlet · InicioServlet
├── filtro/          CodificacionFiltro (UTF-8) · CsrfFiltro · AutenticacionFiltro
└── util/            LectorFormulario (validación) · SeguridadContrasena (PBKDF2)
                     · CatalogoEstados

src/main/webapp/
├── css/estilos.css  Paleta y tipografía corporativas
├── js/aplicacion.js Menú móvil, mostrar contraseña, confirmación de borrado
└── WEB-INF/
    ├── web.xml      Filtros, sesión, codificación JSP y páginas de error
    ├── jspf/        Fragmentos reutilizables (cabecera, pie, campos, mensajes)
    └── vistas/      login, registro, inicio, error y lista/formulario por módulo
```

### Flujo de una petición

1. El navegador envía **GET** (consultar / abrir formulario) o **POST** (guardar,
   actualizar, eliminar) a un servlet, por ejemplo `/clientes`.
2. Los filtros fijan UTF-8, validan el token CSRF y verifican la sesión y el rol.
3. `CrudServlet` lee el parámetro `accion`, valida el formulario con
   `LectorFormulario` y llama al DAO.
4. El DAO ejecuta SQL con `PreparedStatement` (sin concatenar datos del usuario).
5. Tras un POST exitoso se redirige (patrón Post/Redirect/Get) con un mensaje
   flash; en GET se reenvía a la vista JSP en `WEB-INF/vistas`.

### Rutas por módulo

| Método | URL | Operación |
|---|---|---|
| GET | `/clientes?q=texto` | Consultar y buscar |
| GET | `/clientes?accion=nuevo` | Formulario de creación |
| GET | `/clientes?accion=editar&id=5` | Formulario de edición |
| POST | `/clientes` + `accion=guardar` | Insertar |
| POST | `/clientes` + `accion=actualizar` | Actualizar |
| POST | `/clientes` + `accion=eliminar` | Eliminar |

Módulos: `/clientes`, `/vendedores`, `/logistica`, `/transportistas`, `/pedidos`,
`/facturas`, `/envios`, `/incidencias`, `/notificaciones`. Además: `/login`,
`/registro` (crear cuenta de cliente), `/inicio` y `/cerrar-sesion`.

---

## 5. Elementos JSP utilizados

| Elemento | Dónde |
|---|---|
| Directiva `<%@ page %>` (`contentType`, `isErrorPage`) | Todas las vistas; `error.jsp` |
| Directiva `<%@ taglib %>` (JSTL `c`, `fmt`, `fn`) | Todas las vistas |
| Directiva `<%@ include %>` (inclusión estática) | `cabecera.jspf`, `pie.jspf`, `campos-usuario.jspf` |
| Acción `<jsp:include>` + `<jsp:param>` (inclusión dinámica) | `mensajes.jsp`, `error-campo.jsp`, `acciones-fila.jsp`, `barra-busqueda.jsp` |
| Acción `<jsp:useBean>` | `registro.jsp` |
| Expression Language `${...}` | Todas las vistas |
| JSTL `c:forEach`, `c:if`, `c:choose`, `c:set`, `c:url`, `c:out`, `c:redirect` | Listados y formularios |
| `fmt:formatNumber` (moneda COP) · `fn:escapeXml` · `fn:replace` | Listados y formularios |

Las vistas no contienen *scriptlets* (`<% %>`): toda la lógica está en los
servlets y la presentación usa EL y JSTL, como recomienda la especificación.

## 6. Estándares de codificación

- **Paquetes** en minúscula con dominio invertido: `co.homecenter.envios.dao`.
- **Clases** en *PascalCase* con sustantivos: `ClienteDao`, `LectorFormulario`.
- **Métodos y variables** en *camelCase* con verbos para acciones: `buscarPorId`, `leerFormulario`.
- **Constantes** en MAYÚSCULAS con guion bajo: `SQL_INSERTAR`, `ATRIBUTO_USUARIO`.
- **Columnas SQL** en *snake_case* (`id_cliente`) y **propiedades Java** en *camelCase* (`idCliente`).
- **Comentarios Javadoc** en todas las clases y métodos públicos; comentarios de
  bloque en JSP, CSS y SQL.
- Formato: sangría de 4 espacios en Java/JSP, llaves en la misma línea,
  líneas de hasta 120 caracteres, un archivo por clase.

## 7. Seguridad

- Contraseñas guardadas con **PBKDF2-HMAC-SHA256** + sal aleatoria (nunca en texto plano).
- Consultas parametrizadas (`PreparedStatement`) contra inyección SQL.
- Salida escapada con `c:out` / `fn:escapeXml` contra XSS.
- Token **CSRF** en todos los formularios POST.
- Sesión regenerada al iniciar sesión (evita fijación de sesión), cookie `HttpOnly`.
- Autorización por rol: los clientes solo ven su panel; los módulos de
  administración son del personal interno.

## 8. Cambios respecto al script de la evidencia GA6-AA2-EV03

1. Llaves primarias con `AUTO_INCREMENT`.
2. Cliente, Vendedor, Logística y Transportista incluyen `numero_identificacion`
   (único), `telefono` y `contrasena`.
3. `Transportista.id_envio` admite `NULL` (transportista disponible) con `ON DELETE SET NULL`.
4. Restricciones `CHECK` para los estados de pedido, envío e incidencia.
