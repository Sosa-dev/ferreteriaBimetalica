# Incrementos del frontend Flutter — Sprints 1 a 4

## 1. Propósito y alcance

Este documento registra los incrementos realizados en el frontend Flutter de
Ferretería Bimetálica hasta el Sprint 4 del cronograma. Describe las pantallas,
flujos implementados, integración con la API FastAPI, validaciones ejecutadas
y las limitaciones que deben considerarse en la demostración.

El alcance es el cliente Flutter. La persistencia de datos, autorización,
validación definitiva de inventario, cálculo final de la venta y configuración
fiscal dependen de la API.

## 2. Resumen de incrementos

| Sprint | Incremento frontend | Estado |
|---|---|---|
| 1 | Login, registro de clientes, almacenamiento del JWT y navegación según el rol | Implementado |
| 2 | Consulta y mantenimiento de productos, categorías y ubicaciones | Implementado |
| 3 | Catálogo público y búsqueda de productos para empleados | Implementado |
| 4 | Carrito de venta, cobro, visualización e impresión de factura | Implementado, condicionado a configuración fiscal del backend |

## 3. Incremento del Sprint 1: arquitectura y autenticación

### Pantallas y comportamiento

- **Inicio de sesión:** campos de correo y contraseña, validación de campos
  obligatorios, indicador de carga y presentación de errores de autenticación
  o conexión.
- **Registro de cliente:** captura de nombres, apellidos, correo y contraseña.
  La cuenta se registra con el rol de cliente que asigna la API.
- **Inicio por rol:** después del login, la app interpreta el identificador de
  rol devuelto por la API:
  - `1`: propietario.
  - `2`: empleado.
  - `3`: cliente.
- **Cierre de sesión:** elimina el JWT almacenado y regresa al login.

El JWT se guarda usando `flutter_secure_storage` y se adjunta como
`Authorization: Bearer <token>` a las solicitudes protegidas.

### Integración

| Operación | Endpoint | Uso en Flutter |
|---|---|---|
| Iniciar sesión | `POST /auth/login` | Envía `username` (correo) y `password` como formulario OAuth2 |
| Registrar cliente | `POST /usuarios/registro` | Crea una cuenta de cliente |

### Consideraciones

- El formulario público de registro **no crea empleados ni propietarios**.
- La app no restaura automáticamente la sesión al volver a abrirse; el JWT se
  guarda durante la sesión, pero el arranque comienza en el login.
- Los módulos disponibles cambian según el rol. La búsqueda interna, el
  inventario y el POS se presentan a empleados y propietarios; el catálogo se
  presenta a clientes.

## 4. Incremento del Sprint 2: inventario

La pantalla **Inventario** tiene pestañas para Productos, Categorías y
Ubicaciones.

### Productos

- Lista de productos obtenidos de la API.
- Formulario para crear y editar código, nombre, marca, descripción,
  presentación, precios, existencias, stock mínimo, URL de fotografía,
  categoría y ubicación.
- Eliminación con confirmación.
- Validación de campos requeridos y tipos numéricos antes del envío.

### Categorías y ubicaciones

- Consulta, creación, edición y eliminación de categorías.
- Consulta, creación, edición y eliminación de ubicaciones, con pasillo,
  estante y nivel.
- Errores del servidor (por ejemplo, restricciones al eliminar un elemento en
  uso) se presentan en la interfaz.

### Integración

| Operación | Endpoints |
|---|---|
| Productos | `GET /productos`, `POST /productos`, `PUT /productos/{id}`, `DELETE /productos/{id}` |
| Categorías | `GET /categorias`, `POST /categorias`, `PUT /categorias/{id}`, `DELETE /categorias/{id}` |
| Ubicaciones | `GET /ubicaciones`, `POST /ubicaciones`, `PUT /ubicaciones/{id}`, `DELETE /ubicaciones/{id}` |

### Consideraciones

- Estos endpoints requieren un usuario autorizado por la API; el frontend no
  sustituye los controles de rol del servidor.
- Las fotografías se capturan como URL. La app no carga archivos de imagen.
- Para una nueva ubicación se capturan pasillo, estante y nivel. La categoría
  se registra con su nombre; la descripción opcional no tiene un campo en el
  formulario actual.

## 5. Incremento del Sprint 3: catálogo y búsqueda

### Catálogo para clientes

- Presentación de productos en cuadrícula adaptable al ancho disponible.
- Muestra fotografía cuando hay URL válida; si no, utiliza un icono
  ilustrativo.
- Muestra nombre, marca o código y precio.
- No presenta existencia ni ubicación interna.

### Búsqueda para empleados

- Presentación en lista tabular mediante tarjetas.
- Muestra código, categoría, precio, existencia, mínimo, pasillo, estante y
  nivel.
- Búsqueda con espera breve mientras se escribe para reducir solicitudes
  repetidas.
- Selector de criterio: nombre, código, marca, categoría o medida.

### Integración

| Operación | Endpoint |
|---|---|
| Catálogo público | `GET /catalogo/productos` |
| Búsqueda con existencia y ubicación | `GET /productos/buscar` |

Los parámetros de búsqueda utilizados son `nombre`, `codigo`, `marca`,
`categoria` y `medida`.

### Consideraciones

- La interfaz permite seleccionar **un criterio a la vez**. La API permite
  combinar parámetros, pero el frontend todavía no ofrece una pantalla de
  filtros combinados.
- La consulta inicial usa la lista de catálogo/búsqueda paginada de la API.

## 6. Incremento del Sprint 4: punto de venta y facturación

### Punto de venta

- Búsqueda de productos disponibles para el usuario empleado.
- Agregar productos al carrito, aumentar/disminuir cantidades y retirar
  productos.
- Validación local de cantidades contra las existencias recibidas en búsqueda.
- Captura de tipo de cliente (natural o jurídico), nombre/razón social y
  número de documento.
- Presentación de subtotal, IVA de referencia (13 %) y total estimado.
- Envío de venta y datos de facturación a la API.

### Factura

- Presenta los datos devueltos por la API: emisor, cliente, detalles,
  subtotal, IVA y total.
- Permite imprimir o guardar como PDF desde las opciones del sistema mediante
  los paquetes `pdf` y `printing`.
- Si la venta se registra pero la API no puede entregar datos fiscales, la
  pantalla informa la condición y conserva el comprobante de la venta; la
  impresión fiscal se deshabilita.

### Integración

| Operación | Endpoint |
|---|---|
| Registrar venta | `POST /ventas` |
| Obtener factura | `GET /ventas/{id}/factura` |

El payload de venta contiene `items` (identificador del producto y cantidad) y
`datos_facturacion` (tipo, nombre/razón social y documento). El backend es la
fuente autoritativa para validar existencias, descontar stock, calcular los
importes y registrar la venta.

### Dependencias y límites

- La factura requiere que el backend tenga definidos los datos fiscales del
  emisor. Si faltan, la API puede registrar la venta, pero responderá un error
  al consultar la factura.
- La app genera un documento PDF imprimible a partir de los datos JSON que
  devuelve la API; no consume un archivo PDF generado por el servidor.
- El POS no incluye selección de método de pago ni registro de pagos parciales.
- El precio e IVA mostrados antes de cobrar son una vista previa. Se deben
  considerar definitivos los importes de la respuesta de la API.

## 7. Arquitectura Flutter relacionada

- `lib/main.dart`: tema visual y punto de entrada.
- `lib/core/api_client.dart`: configuración de Dio, URL base, JWT y conversión
  de errores de API a mensajes para la interfaz.
- `lib/models/product.dart`: modelo de producto compartido por catálogo,
  búsqueda, inventario y POS.
- `lib/screens/auth_screens.dart`: login y registro.
- `lib/screens/home_screen.dart`: navegación inicial según el rol.
- `lib/screens/inventory_screen.dart`: productos, categorías y ubicaciones.
- `lib/screens/catalog_screen.dart`: catálogo de clientes y búsqueda de
  empleados.
- `lib/screens/pos_screen.dart`: carrito, cobro y solicitud de factura.
- `lib/screens/invoice_screen.dart`: vista e impresión de factura.

La apariencia conserva la paleta azul grisácea de la pantalla inicial, con
controles Material, tarjetas y formularios adaptados a pantallas móviles.

## 8. Configuración y ejecución

### Emulador Android

Desde la carpeta del proyecto Flutter:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` permite que el emulador Android acceda al `localhost` de la
computadora anfitriona.

### Flutter Web en Edge

```powershell
flutter run -d edge --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Al usar Flutter Web, la API debe permitir mediante CORS el origen desde el que
Flutter sirve la aplicación. En un dispositivo físico se debe sustituir la
dirección por la IP LAN de la computadora donde corre FastAPI. En producción,
se recomienda HTTPS.

## 9. Verificación realizada

Se ejecutaron las siguientes verificaciones durante el desarrollo:

- `flutter analyze`: sin problemas reportados.
- `flutter test`: pruebas de widget aprobadas, incluida la navegación desde
  **Sign up** hasta el registro.
- `flutter build apk --debug`: APK Android de depuración compilado.
- Pruebas existentes de la API Sprint 3/4: 11 pruebas aprobadas.

Las pruebas de backend verifican contratos y reglas del servidor; no sustituyen
una prueba de extremo a extremo contra una instancia de API y base de datos
configuradas para demostración.

## 10. Archivos principales

- App Flutter: `lib/`
- Prueba de navegación: `test/widget_test.dart`
- Dependencias Flutter: `pubspec.yaml`
- Configuración Android de red: `android/app/src/main/AndroidManifest.xml`
