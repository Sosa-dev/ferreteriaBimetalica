# 03. Mapa de pantallas y recorrido de datos

Los árboles son una vista simplificada de cómo se anidan los widgets: se
omiten algunos `SizedBox`, separadores y decoraciones repetidas para favorecer
la lectura. Los archivos están bajo `lib/`. La aplicación no usa un router
declarativo: las pantallas se abren con `Navigator` y `MaterialPageRoute`.

## Navegación general

```text
FerreteriaApp
└── MaterialApp (tema global)
    └── LoginScreen
        ├── RegisterScreen
        └── HomeScreen (después de autenticar)
            ├── Cliente: CatalogScreen
            │   ├── OrderCartScreen
            │   └── CustomerOrdersScreen
            └── Empleado/propietario
                ├── StaffOrdersScreen
                ├── InventoryScreen
                │   ├── ProductFormScreen
                │   └── _CatalogEntryDialog
                ├── CatalogScreen(employeeMode: true)
                └── PosScreen
                    └── InvoiceScreen
```

`MaterialPageRoute` crea cada destino. `push` agrega una pantalla; `pop` vuelve
y puede entregar un resultado; `pushReplacement` cambia la pantalla actual;
`pushAndRemoveUntil` limpia la pila, por ejemplo al cerrar sesión.

## 1. Login — `screens/auth_screens.dart:7-169`

```text
Scaffold
└── SafeArea
    └── Center
        └── SingleChildScrollView
            └── ConstrainedBox (máximo 420 px)
                └── Form
                    └── Column
                        ├── Image.asset (logo)
                        ├── Text (marca y título)
                        ├── TextFormField (correo)
                        ├── TextFormField (contraseña)
                        │   └── suffixIcon: IconButton (mostrar/ocultar)
                        ├── FilledButton (Ingresar/loading)
                        └── OutlinedButton.icon (registro)
```

**Flujo de datos:** `TextEditingController` → validación del `Form` → Dio
`POST /auth/login` como formulario OAuth2 (`username`, `password`) → JSON con
`access_token`, `id_rol`, nombre y correo → `ApiClient.saveToken` → argumentos
de `HomeScreen` → presentación del usuario en home.

No hay modelo de login dedicado: la respuesta se lee como `Map`. Dio adjunta el
token guardado a las solicitudes posteriores mediante un interceptor.

## 2. Registro — `screens/auth_screens.dart:171-288`

```text
Scaffold
├── AppBar ("Registro de cliente")
└── SafeArea
    └── Center
        └── SingleChildScrollView
            └── ConstrainedBox (máximo 460 px)
                └── Form
                    └── Column
                        ├── TextFormField (nombres)
                        ├── TextFormField (apellidos)
                        ├── TextFormField (correo)
                        ├── TextFormField (contraseña)
                        └── FilledButton (crear cuenta/loading)
```

**Flujo de datos:** controladores → validación de campos obligatorios → Dio
`POST /usuarios/registro` con nombres, apellidos, correo y contraseña → API
crea cliente con rol cliente → mensaje `SnackBar` → `Navigator.pop` regresa al
login. No se recibe token automáticamente tras el registro.

## 3. Home por rol — `screens/home_screen.dart:10-203`

```text
Scaffold
├── AppBar
│   └── IconButton (cerrar sesión)
└── SafeArea
    └── ListView
        ├── Container de bienvenida
        │   └── Column (logo, nombre, correo, Chip del rol)
        ├── Text (pregunta de inicio)
        └── Card + ListTile por cada _HomeAction permitido
            ├── CircleAvatar + Icon
            ├── Text (título)
            ├── Text (descripción)
            └── onTap → Navigator.push
```

**Flujo de datos:** recibe nombre, correo e ID de rol desde login. `roleId`
selecciona el nombre y los módulos: cliente ve catálogo y pedidos propios;
roles 1/2 ven pedidos, inventario, búsqueda de empleado y POS. Al cerrar
sesión, `ApiClient.clearToken` elimina JWT y la pila vuelve al login. El home
no vuelve a consultar perfil a FastAPI.

## 4. Catálogo de cliente — `screens/catalog_screen.dart:10-377`

```text
Scaffold
├── AppBar
│   ├── Row (logo + nombre de marca)
│   └── IconButton + Badge (carrito)
└── Column
    ├── Container (mensaje de orientación)
    ├── Padding
    │   └── TextField (búsqueda)
    ├── LinearProgressIndicator (si loading)
    ├── mensaje + TextButton (si error)
    └── Expanded
        └── LayoutBuilder
            ├── Center (estado vacío)
            └── GridView.builder
                └── _productCard
                    └── Card
                        ├── ProductPhoto
                        └── Padding + Column
                            ├── Text (nombre/marca)
                            ├── Text (precio)
                            └── FilledButton.icon (agregar)
```

**Flujo de datos:** el `TextField` y debounce → Dio `GET
/catalogo/productos?nombre=...&limit=50` → lista JSON → `Product.fromJson`
normaliza tipos → `_products` en `State` → `GridView.builder` → `_productCard`.
Al agregar: `Product` → mapa local `_cart` de `OrderCartLine` → número del
`Badge`. No se llama API hasta confirmar el pedido.

El cliente solo ve búsqueda por nombre en esta pantalla; los filtros detallados
por código/marca/categoría/medida se muestran en modo empleado.

## 5. Búsqueda de empleado — misma clase, modo `employeeMode: true`

```text
Scaffold
├── AppBar ("Búsqueda de productos")
└── Column
    ├── Padding
    │   ├── TextField (texto)
    │   └── DropdownButtonFormField (campo: nombre/código/marca/categoría/medida)
    ├── LinearProgressIndicator / error
    └── Expanded
        └── ListView.builder
            └── Card + ListTile
                ├── CircleAvatar
                ├── Text (producto)
                ├── Text (categoría, ubicación, stock y mínimo)
                └── Text (precio)
```

**Flujo de datos:** texto + selector → Dio `GET /productos/buscar` con filtro
seleccionado y límite → JSON que incluye existencias y localización → mismo
modelo `Product` (con campos internos opcionales) → `_products` → lista de
resultados.

## 6. Inventario — `screens/inventory_screen.dart:7-280`

```text
DefaultTabController (length 3)
└── Scaffold
    ├── AppBar
    │   └── TabBar
    │       ├── Tab Productos
    │       ├── Tab Categorías
    │       └── Tab Ubicaciones
    └── body: loading / _ErrorState / TabBarView
        ├── _productList
        │   └── RefreshIndicator
        │       └── ListView
        │           ├── FilledButton (agregar)
        │           └── Card + ListTile por producto
        │               ├── ClipRRect + ProductPhoto
        │               └── Wrap (editar/eliminar)
        ├── _entryList de categorías
        └── _entryList de ubicaciones
            └── RefreshIndicator + ListView + Card/ListTile
```

**Flujo de datos inicial:** `_load` → `Future.wait` en paralelo →
`GET /productos`, `GET /categorias`, `GET /ubicaciones` → las filas de producto
se convierten a `Product`; categorías/ubicaciones quedan como mapas →
`_products`, `_categories`, `_locations` → estado de pestañas.

Los botones de crear/editar/borrar llaman POST/PUT/DELETE. Al volver de
`ProductFormScreen` con `pop(true)`, se vuelve a llamar `_load`.

## 7. Formulario de producto — `screens/inventory_screen.dart:283-511`

```text
Scaffold
├── AppBar (nuevo/editar)
└── Form
    └── ListView
        ├── TextFormField (código, nombre, marca, medida, precios, stock, URL,
        │                  descripción)
        ├── DropdownButtonFormField<int> (categoría)
        ├── DropdownButtonFormField<int> (ubicación, isExpanded)
        └── FilledButton (guardar/loading)
```

**Flujo de datos:** la pantalla padre entrega categorías, ubicaciones y producto
opcional → campos/controladores → validación → payload numérico →
POST `/productos` o PUT `/productos/{id}` → `Navigator.pop(true)` → padre
recarga. Los selectores `isExpanded` y textos con elipsis permiten opciones
largas en pantalla angosta.

## 8. Diálogo de categoría/ubicación — `screens/inventory_screen.dart:513-613`

```text
AlertDialog
├── title
├── content: Column
│   ├── TextField (nombre o pasillo)
│   ├── TextField (estante, solo ubicación)
│   └── TextField (nivel, solo ubicación)
└── actions (cancelar/guardar)
```

**Flujo de datos:** valores de controladores → `Navigator.pop` con mapa de
resultado → `_editCatalogEntry` decide POST o PUT → endpoint
`/categorias` o `/ubicaciones` → `_load`.

## 9. Punto de venta — `screens/pos_screen.dart:7-318`

```text
Scaffold
├── AppBar
└── SafeArea
    └── ListView
        ├── TextField (buscar)
        ├── progreso/error
        ├── Cards de coincidencias (agregar)
        ├── Cards de líneas del carrito (menos/cantidad/más)
        ├── Card resumen (subtotal/IVA/total)
        ├── DropdownButtonFormField (tipo persona)
        ├── TextField (nombre y documento)
        └── FilledButton.icon (cobrar)
```

**Flujo de datos:** texto → Dio `GET /productos/buscar?nombre=...` →
`Product.fromJson` → resultados → `_CartLine` local. Cobro: carrito + datos
fiscales → Dio `POST /ventas` → respuesta de venta con detalles e importes →
Dio `GET /ventas/{id}/factura` → `InvoiceScreen(sale, invoice, invoiceError)`.
Subtotal/IVA del cliente son una vista previa; el servidor es autoritativo.

## 10. Factura — `screens/invoice_screen.dart:8-276`

```text
Scaffold
├── AppBar
└── ListView
    ├── Card del emisor/cliente
    ├── Card de error fiscal + reintento, si aplica
    ├── Cards/ListTile de productos
    ├── Card de resumen de importes
    └── FilledButton (imprimir/guardar)
```

**Flujo de datos:** recibe `sale` y `invoice`; pinta los mapas recibidos. Si
falta factura, `_retryInvoice` repite `GET /ventas/{id}/factura`; reimpresión
construye `pw.Document` usando `package:pdf` y lo envía a `Printing.layoutPdf`.
No se recibe un PDF del servidor.

## 11. Carrito de pedido — `screens/order_screens.dart:6-212`

```text
Scaffold
├── AppBar
└── body
    ├── Center (carrito vacío + volver), o
    └── Column
        ├── Expanded
        │   └── ListView de Card por OrderCartLine
        │       └── Row (producto, subtotal, menos, cantidad, más)
        └── SafeArea
            └── Padding + Column (total, error, confirmar)
```

**Flujo de datos:** recibe el mapa de carrito del catálogo; ajustes modifican
el mapa y notifican al padre por `onCartChanged`; confirmar envía Dio
`POST /pedidos` con `items: [{producto_id, cantidad}]`; respuesta trae ID; se
limpia carrito y abre `CustomerOrdersScreen`.

## 12. Mis pedidos — `screens/order_screens.dart:214-373`

```text
Scaffold
├── AppBar
└── loading / _ErrorPanel / RefreshIndicator
    └── ListView.builder
        └── Card + ExpansionTile por pedido
            └── _orderDetails
                ├── CircularProgressIndicator, o
                ├── mensaje de vacío/error, o
                └── Column de ListTile por línea
```

**Flujo de datos:** initState → Dio `GET /pedidos` → mapas JSON → `_orders` →
filas. Al expandir una fila, Dio `GET /pedidos/{id}/detalles` → `_details[id]`
→ nombre/código/cantidad/precio mostrados. El servidor filtra el listado para
que el cliente vea solo lo propio.

## 13. Gestión de pedidos — `screens/order_screens.dart:375-510`

```text
Scaffold
├── AppBar
└── loading / _ErrorPanel / RefreshIndicator
    └── ListView.builder
        └── Card + Padding + Column
            ├── ListTile (pedido, cliente, fecha, total, Chip de estado)
            └── Align + FilledButton.tonal (siguiente estado)
```

**Flujo de datos:** initState → Dio `GET /pedidos` → `_orders` → tarjetas.
Acción de estado → Dio `PUT /pedidos/{id}` con `estado` → vuelve a cargar la
lista. El servidor verifica que sea empleado/propietario y que la transición
sea la siguiente permitida.

## 14. Estados de error, vacío y foto

```text
_ErrorPanel / _ErrorState
└── Center → Padding → Column → Text + OutlinedButton/TextButton (reintentar)

_EmptyState
└── Padding → mensaje

ProductPhoto
├── URL vacía → ColoredBox → Center → Icon placeholder
└── URL disponible → Image.network
    ├── mientras carga → ColoredBox → Center → CircularProgressIndicator
    └── error → placeholder de imagen no disponible
```

Estos componentes son ramas visuales del mismo flujo de datos, no endpoints
separados.

## Convención para seguir una solicitud desde la UI hasta FastAPI

Usa esta cadena en tus notas:

```text
Evento (tap/texto)
→ método de pantalla
→ ApiClient.instance.dio (Dio/interceptor)
→ endpoint FastAPI
→ respuesta JSON
→ modelo Product o Map
→ setState
→ build
→ Text/ListTile/Card/GridView en pantalla
```

Si la respuesta es una escritura, rastrea también la transacción del backend y
la respuesta HTTP; no asumas que el dato se guardó solo porque el botón recibió
un tap.
