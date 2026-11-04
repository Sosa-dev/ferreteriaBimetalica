# 01. Inventario y fichas de widgets

Guía basada en el código que existe en `lib/` del proyecto Flutter. Las líneas
se refieren a los archivos actuales de esa carpeta. Los widgets de framework
son de Flutter/Material; los widgets `pw.*` pertenecen al lenguaje de
composición de PDF de `package:pdf`, no a la interfaz Flutter que se muestra
en pantalla.

## Cómo leer las fichas

Para evitar repetir explicaciones idénticas decenas de veces, cada ficha de
familia enumera sus widgets individuales y explica los rasgos propios de cada
uno. El fragmento es código real del proyecto; las líneas numeradas explican
cómo se compone. «Alternativa» compara el uso contextual, no afirma que los
widgets sean intercambiables en todos los casos.

## Índice completo por las diez categorías solicitadas

El índice incluye widgets concretos y clases propias que se dibujan. Los
objetos de estilo/configuración y las APIs de navegación se explican en sus
familias, pero no se cuentan como widgets visuales.

| Categoría | Widgets identificados en la app | Ubicaciones principales |
|---|---|---|
| 1. Estructura base | `MaterialApp`, `Scaffold`, `AppBar`, `SafeArea`, `DefaultTabController` | `main.dart`; pantallas; `inventory_screen.dart` |
| 2. Layout | `Center`, `Column`, `Row`, `Expanded`, `Padding`, `SizedBox`, `Container`, `ConstrainedBox`, `LayoutBuilder`, `Wrap`, `ClipRRect`, `Align`, `Spacer` | Formularios, catálogo, home, inventario, pedidos y factura |
| 3. Listas y scroll | `ListView`, `ListView.builder`, `GridView.builder`, `SingleChildScrollView`, `RefreshIndicator`, `TabBarView`, `ExpansionTile` | Catálogo, inventario, home, factura y pedidos |
| 4. Entrada y formularios | `Form`, `TextFormField`, `TextField`, `DropdownButtonFormField`, `DropdownMenuItem` | Login, registro, inventario, POS, catálogo |
| 5. Botones e interacción | `FilledButton` (incluye `.icon`, `.tonal`, `.tonalIcon`), `OutlinedButton` (incluye `.icon`), `TextButton`, `IconButton`, `SnackBar`, `AlertDialog`, `Badge`, `Chip` | Todas las pantallas de flujo |
| 6. Navegación y rutas | `Navigator` y `MaterialPageRoute` son APIs de navegación, no widgets; `Tab`, `TabBar` sí son widgets | Home, auth, inventario, pedidos, POS |
| 7. Estado | `StatefulWidget`, `StatelessWidget`; `State`/`setState` administran estado, no son nodos UI | Formularios y pantallas de carga |
| 8. Asincronía y datos | Indicadores `CircularProgressIndicator`, `LinearProgressIndicator`; imágenes `Image.asset`, `Image.network`; HTTP Dio no es widget | Cliente, catálogo, POS, inventario |
| 9. Estilo y tema | `Text`, `Card`, `ListTile`, `Icon`, `CircleAvatar`, `ColoredBox`, `Divider` | Tema y pantallas |
| 10. Widgets propios | `FerreteriaApp`, `LoginScreen`, `RegisterScreen`, `HomeScreen`, `CatalogScreen`, `InventoryScreen`, `ProductFormScreen`, `_CatalogEntryDialog`, `_EmptyState`, `_ErrorState`, `PosScreen`, `InvoiceScreen`, `OrderCartScreen`, `CustomerOrdersScreen`, `StaffOrdersScreen`, `_ErrorPanel`, `ProductPhoto` | `main.dart`, `screens/`, `widgets/` |

Algunas clases cumplen dos funciones: por ejemplo, `RefreshIndicator` interactúa
con una lista y la envuelve. Se clasifica aquí por su uso principal. `TextStyle`,
`Color`, `BoxDecoration`, `EdgeInsets`, `CardThemeData`,
`InputDecorationTheme`, `Dio`, `Navigator` y `MaterialPageRoute` aparecen en
el código, pero no todos son widgets visuales.

## 1. Estructura base

### `MaterialApp`

- **Qué hace:** configura la aplicación Material: tema, título, rutas y pantalla
  inicial.
- **Dónde:** `lib/main.dart:14-70`, clase `FerreteriaApp`.
- **Ejemplo real:**

  ```dart
  return MaterialApp(
    title: 'Ferretería Bimetálica',
    theme: ThemeData(...),
    home: const LoginScreen(),
  );
  ```

- **Línea por línea:** `MaterialApp` establece el contexto Material; `title`
  identifica la app; `theme` comparte el diseño; `home` inicia en login.
- **Propiedades importantes:** `title`, `theme`, `home`,
  `debugShowCheckedModeBanner`.
- **Por qué aquí:** todas las pantallas necesitan el tema Material y un punto
  de entrada. Una app sin Material necesitaría construir más infraestructura
  manualmente.
- **Error frecuente:** pensar que `home` controla todas las navegaciones; aquí
  solo define la pantalla inicial, y el resto usa `Navigator`.
- **Ejercicio:** cambia temporalmente el título y comprueba que el árbol de
  pantallas no cambia.

### `Scaffold`, `AppBar`, `SafeArea` y `DefaultTabController`

- **Qué hacen:** `Scaffold` da estructura visual de pantalla; `AppBar` aporta
  cabecera; `SafeArea` evita zonas físicas como la cámara/notch; y
  `DefaultTabController` coordina pestañas sin crear un controlador manual.
- **Dónde:** `Scaffold` se usa en todas las pantallas principales; `AppBar` en
  home, catálogo, inventario, pedidos, POS y factura; `SafeArea` en login,
  registro, home y carrito; `DefaultTabController` en
  `lib/screens/inventory_screen.dart:135`.
- **Ejemplo real:**

  ```dart
  DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        bottom: const TabBar(tabs: [...]),
      ),
      body: ...,
    ),
  )
  ```

- **Línea por línea:** se declara que hay tres pestañas; el `Scaffold` contiene
  la pantalla; el `AppBar` presenta el título; `bottom` coloca la barra debajo
  del título; `body` muestra el contenido asociado.
- **Propiedades importantes:** `Scaffold.appBar/body`; `AppBar.title/actions/
  bottom`; `SafeArea.child`; `DefaultTabController.length/child`.
- **Por qué aquí:** `Scaffold` es el patrón estándar de pantalla Material;
  `SafeArea` es más claro que sumar márgenes arbitrarios; el controlador
  predeterminado basta para las tres pestañas fijas de inventario.
- **Error frecuente:** declarar diferente `length` y cantidad de `Tab`; omitir
  `SafeArea` donde el contenido toca los bordes del dispositivo.
- **Ejercicio:** agrega una cuarta pestaña y su contenido y conserva el mismo
  orden en `TabBar` y `TabBarView`.

## 2. Layout

### `Column` y `Row`

- **Qué hacen:** organizan hijos vertical u horizontalmente.
- **Dónde:** formularios, tarjetas, resumen de factura y carrito. Ejemplos:
  `auth_screens.dart:79`, `catalog_screen.dart:124`,
  `order_screens.dart:123`.
- **Ejemplo real:**

  ```dart
  Row(
    children: [
      Expanded(child: Column(children: [... ])),
      IconButton(...),
    ],
  )
  ```

- **Línea por línea:** `Row` pone los controles en una línea; `Expanded` toma el
  ancho sobrante; `Column` apila información del artículo; `IconButton` deja
  los controles a la derecha.
- **Propiedades:** `children`, `mainAxisAlignment`,
  `crossAxisAlignment`, `mainAxisSize`.
- **Alternativas:** `Wrap` cuando no cabe una fila rígida; `ListView` cuando hay
  muchos hijos o se necesita scroll.
- **Error común:** colocar hijos de altura ilimitada en un `Column` dentro de
  un scroll, u olvidar `Expanded` en una fila estrecha.
- **Ejercicio:** coloca nombre y precio en una fila que responda bien a 320 px.

### `Expanded` y `Spacer`

- **Qué hacen:** `Expanded` asigna espacio flexible a un hijo de `Row`/`Column`;
  `Spacer` consume espacio libre sin contenido.
- **Dónde:** `catalog_screen.dart:128,207`, `order_screens.dart:115,125`,
  `invoice_screen.dart:86`.
- **Ejemplo real:**

  ```dart
  Expanded(child: ListView.builder(...))
  ```

- **Explicación:** el `Column` da la zona restante al listado; el constructor
  `builder` produce solo elementos visibles; el scroll ocupa esa zona.
- **Propiedades:** `flex` y `child` en `Expanded`; `flex` en `Spacer`.
- **Alternativas:** `Flexible` permite que el hijo use menos espacio; `SizedBox`
  sirve para una dimensión fija.
- **Error común:** usar `Expanded` fuera de `Row`, `Column` o `Flex`, o anidar
  flexibles dentro de un padre con altura no acotada.
- **Ejercicio:** en una pantalla de resumen, empuja el total al fondo mediante
  `Spacer`.

### `Padding`, `SizedBox`, `Container` y `Center`

- **Qué hacen:** `Padding` crea separación interna; `SizedBox` fija una medida
  o un espacio; `Container` combina tamaño, padding y decoración; `Center`
  centra un hijo.
- **Dónde:** por todo el proyecto: `catalog_screen.dart:89,150,220`,
  `home_screen.dart:99`, `order_screens.dart:175`.
- **Ejemplo real:**

  ```dart
  Padding(
    padding: const EdgeInsets.all(10),
    child: Column(children: [...]),
  )
  ```

- **Línea por línea:** `Padding` agrega 10 px por lado; `EdgeInsets.all` crea
  márgenes iguales; `child` es el contenido que recibe ese espacio.
- **Propiedades:** `padding`; `width/height`; `alignment`; `decoration`; `child`.
- **Alternativas:** para solo separar dos hijos, un `SizedBox` es más explícito
  y ligero que un `Container` sin decoración.
- **Error común:** encadenar varios `Container` para lograr únicamente
  padding, o confundir padding interno con margin externo.
- **Ejercicio:** ajusta el espacio entre los campos de registro sin cambiar el
  tamaño del botón.

### `ConstrainedBox`, `LayoutBuilder` y `Wrap`

- **Qué hacen:** `ConstrainedBox` aplica límites; `LayoutBuilder` entrega las
  restricciones disponibles al construir; `Wrap` acomoda elementos en filas o
  columnas siguientes cuando ya no caben.
- **Dónde:** `ConstrainedBox` limita login/registro
  (`auth_screens.dart:75,236`); `LayoutBuilder` decide columnas
  (`catalog_screen.dart:208`); `Wrap` agrupa controles del inventario
  (`inventory_screen.dart:209,256`).
- **Ejemplo real:**

  ```dart
  LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000 ? 4 : 2;
      return GridView.builder(...);
    },
  )
  ```

- **Línea por línea:** recibe el espacio del padre; `constraints.maxWidth`
  informa el ancho; se calcula el número de columnas; el grid se crea con esa
  decisión.
- **Propiedades:** `constraints`; `builder`; `spacing/runSpacing` y alineación
  en `Wrap`.
- **Alternativas:** `MediaQuery` consulta tamaño de pantalla; `Row` no envuelve
  sus hijos automáticamente.
- **Error común:** usar el ancho global del dispositivo cuando el componente
  está dentro de un panel más angosto.
- **Ejercicio:** crea tres breakpoints para 2, 3 y 4 columnas en el catálogo.

### `ClipRRect`, `Align` y `Divider`

- **Qué hacen:** `ClipRRect` recorta al radio indicado; `Align` ubica un hijo
  dentro de su espacio; `Divider` dibuja una separación visual.
- **Dónde:** recorte de foto en inventario (`inventory_screen.dart:195`);
  alineación de factura y acciones (`invoice_screen.dart:87`,
  `order_screens.dart:486`); separación de importes (`pos_screen.dart:250`,
  `invoice_screen.dart:166`).
- **Ejemplo real:** `ClipRRect(borderRadius: BorderRadius.circular(8), child:
  ProductPhoto(...))`.
- **Explicación:** crea una máscara redondeada; define el radio; el contenido
  recortado es la foto del producto.
- **Propiedades:** `borderRadius/child`; `alignment/child`; grosor, indentación
  y color de `Divider`.
- **Alternativas:** `BoxDecoration` también dibuja esquinas, pero no recorta
  automáticamente una imagen hija; `Spacer` separa sin trazar una línea.
- **Error común:** creer que decorar el padre siempre recorta sus imágenes.
- **Ejercicio:** aplica un recorte circular a la miniatura y compara el
  resultado con `ClipRRect`.

## 3. Listas y scroll

### `ListView`, `ListView.builder` y `SingleChildScrollView`

- **Qué hacen:** permiten desplazar contenido vertical. `ListView.builder`
  construye elementos bajo demanda; `SingleChildScrollView` desplaza un único
  hijo compuesto.
- **Dónde:** home, formularios, inventario, POS, carrito, pedidos y factura.
- **Ejemplo real:** `ListView.builder(padding: ..., itemCount: _products.length,
  itemBuilder: (context, index) => _productCard(_products[index]))`.
- **Explicación:** reserva un área desplazable; aplica margen interno; conoce
  cuántas filas existen; crea cada fila cuando se necesita.
- **Propiedades:** `children`, `itemCount`, `itemBuilder`, `padding`,
  `scrollDirection`, `shrinkWrap`.
- **Alternativas:** un `Column` vale para pocos elementos fijos; builder escala
  mejor con colecciones largas.
- **Error común:** poner una lista extensa dentro de otra lista vertical sin
  decidir cuál controla el scroll.
- **Ejercicio:** cambia una lista pequeña del inventario a `ListView.builder`.

### `GridView.builder` y `SliverGridDelegateWithFixedCrossAxisCount`

- **Qué hacen:** muestran productos en cuadrícula perezosa; el delegate define
  cuántas columnas y qué tamaño/espacio tendrá cada tarjeta.
- **Dónde:** `catalog_screen.dart:247-258`.
- **Ejemplo real:**

  ```dart
  GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisExtent: 286,
    ),
    itemCount: _products.length,
    itemBuilder: (context, index) => _productCard(_products[index]),
  )
  ```

- **Línea por línea:** crea una cuadrícula virtualizada; el delegate recibe el
  número adaptativo; fija alto de tarjeta; limita cantidad; construye tarjeta.
- **Propiedades:** `crossAxisCount`, `mainAxisExtent`,
  `childAspectRatio`, `crossAxisSpacing`, `mainAxisSpacing`.
- **Alternativas:** `ListView` para datos comparables en tabla/filas; `Wrap`
  para pocos chips sin virtualización.
- **Error común:** fijar aspecto o altura que recorta textos a escala de fuente
  grande.
- **Ejercicio:** prueba una altura de tarjeta diferente con nombre largo y
  activa una escala de texto mayor.

### `RefreshIndicator`, `TabBarView` y `ExpansionTile`

- **Qué hacen:** refrescan al deslizar hacia abajo; presentan el contenido de
  la pestaña elegida; y expanden una fila para mostrar detalle.
- **Dónde:** actualización de inventario/pedidos; pestañas de inventario;
  detalle de “Mis pedidos”.
- **Ejemplo real:** `RefreshIndicator(onRefresh: _loadOrders, child:
  ListView.builder(...))`.
- **Explicación:** registra una acción asíncrona; exige una lista desplazable
  compatible; al gesto llama al método que consulta la API.
- **Propiedades:** callback `onRefresh` debe devolver `Future`; `TabBarView`
  recibe `children`; `ExpansionTile` usa `title`, `leading`,
  `onExpansionChanged`, `children`.
- **Alternativas:** botón de recarga si el gesto no es evidente; acordeón propio
  si se necesita control más complejo.
- **Error común:** envolver un hijo no desplazable en `RefreshIndicator`, o
  que el future termine antes de actualizar la lista.
- **Ejercicio:** agrega al encabezado del pedido el conteo de líneas al
  expandirlo.

## 4. Entrada de datos y formularios

### `Form` y `TextFormField`

- **Qué hacen:** `Form` agrupa campos y permite validarlos con una clave;
  `TextFormField` combina edición de texto con validación.
- **Dónde:** login, registro y formulario de producto.
- **Ejemplo real:**

  ```dart
  Form(
    key: _formKey,
    child: TextFormField(
      controller: _emailController,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Ingresa tu correo' : null,
    ),
  )
  ```

- **Línea por línea:** crea el grupo; conecta la clave; pone el campo dentro;
  conecta el controlador; el validador devuelve mensaje o `null`.
- **Propiedades:** `key`, `child`, `controller`, `validator`,
  `keyboardType`, `decoration`, `obscureText`.
- **Alternativas:** `TextField` sin Form cuando no se requiere validación
  integrada; validación de dominio en API siempre complementa la de interfaz.
- **Error común:** llamar `validate()` sin poner los campos bajo el `Form`
  correcto, o creer que la validación cliente protege la API.
- **Ejercicio:** exige una contraseña de al menos 8 caracteres en el registro.

### `TextField` y `DropdownButtonFormField`

- **Qué hacen:** `TextField` recoge texto sin validación integrada; el menú
  desplegable selecciona un valor de un conjunto conocido.
- **Dónde:** búsqueda de catálogo/POS, datos de factura, campos del diálogo;
  filtros de empleado, tipo de cliente y categorías/ubicaciones.
- **Ejemplo real:** el selector de ubicación de producto tiene
  `initialValue`, `isExpanded: true`, `decoration`, `items` y `onChanged`
  (`inventory_screen.dart:453-469`).
- **Línea por línea:** establece selección actual; ocupa el ancho; muestra
  etiqueta; transforma cada ubicación en opción; actualiza el ID seleccionado.
- **Propiedades:** `controller`, `onChanged`, `keyboardType`,
  `obscureText`; `initialValue`, `isExpanded`, `items`, `decoration`.
- **Alternativas:** `TextFormField` para validación del grupo; diálogo de
  búsqueda para catálogos con cientos de opciones.
- **Error común:** olvidar `isExpanded` con textos largos y causar overflow;
  poner un valor inicial que no exista en `items`.
- **Ejercicio:** agrega búsqueda por categoría con menú y valida una pantalla
  de 320 px.

### `DropdownMenuItem`, `InputDecoration` y `InputDecorationTheme`

- **Qué hacen:** `DropdownMenuItem` representa una opción; `InputDecoration`
  define etiqueta/iconos/borde de un campo; el theme aplica el estilo común.
- **Dónde:** opciones de filtros y factura; `main.dart:30`, formularios.
- **Ejemplo real:** `DropdownMenuItem(value: 'nombre', child: Text('Nombre'))`.
- **Explicación:** el valor es lo que recibe el estado; `child` es el texto que
  ve la persona.
- **Propiedades:** `value`, `child`; `labelText`, `hintText`, `prefixIcon`,
  `suffixIcon`, `border`, `filled`.
- **Alternativas:** texto independiente y selector personalizado si la opción
  necesita imagen o explicación.
- **Error común:** valores duplicados o tipos incompatibles en las opciones.
- **Ejercicio:** añade una opción de “Código” y verifica el parámetro de
  búsqueda enviado.

## 5. Botones e interacción

### `FilledButton`, `OutlinedButton`, `TextButton` e `IconButton`

- **Qué hacen:** acciones primarias, secundarias delineadas, acciones ligeras
  de texto y acciones representadas por icono.
- **Dónde:** guardar/cobrar/confirmar; registro/reintento; cancelar; editar,
  eliminar, carrito, revelar contraseña.
- **Ejemplo real:** `FilledButton(onPressed: _loading ? null : _save, child:
  const Text('Guardar producto'))`.
- **Línea por línea:** define acción destacada; desactiva el botón durante el
  envío; presenta la etiqueta.
- **Propiedades:** `onPressed` (`null` deshabilita), `child`, `icon`,
  `style`, `tooltip`.
- **Alternativas:** no uses iconos para acciones ambiguas; agrega texto o
  tooltip accesible.
- **Error común:** permitir doble envío mientras una petición está activa.
- **Ejercicio:** muestra spinner y deshabilita el botón durante el guardado.

### Constructores con icono y variantes

- **Widgets usados:** `FilledButton.icon`, `FilledButton.tonalIcon`,
  `FilledButton.tonal`, `OutlinedButton.icon`.
- **Dónde:** catálogo, inventario, login, gestión de pedidos y facturación.
- **Fragmento real:** `FilledButton.icon(onPressed: () => _addToCart(product),
  icon: const Icon(Icons.add_shopping_cart), label: const Text('Agregar'))`.
- **Línea por línea:** acción agrega; icono anticipa significado; etiqueta
  confirma la acción.
- **Propiedades:** callback, `icon`, `label`, estilo tonal/filled.
- **Alternativa:** botón de texto en superficies densas; `IconButton` si el
  significado es universal y hay tooltip.
- **Error común:** confiar solo en el icono o no respetar contraste del estilo.
- **Ejercicio:** compara botón tonal y sólido para decidir cuál comunica mejor
  la acción primaria.

### `SnackBar`, `AlertDialog`, `showDialog` y `RefreshIndicator`

- **Qué hacen:** `SnackBar` comunica un resultado temporal; `AlertDialog`
  solicita decisión; `showDialog` lo presenta y devuelve un resultado;
  `RefreshIndicator` activa recarga por gesto.
- **Dónde:** mensajes de éxito/error; confirmación al borrar; diálogo de
  categoría/ubicación; listas recargables.
- **Ejemplo real:** `final confirmed = await showDialog<bool>(context: context,
  builder: (context) => AlertDialog(...))`.
- **Explicación:** espera la decisión; especifica tipo booleano; usa contexto;
  construye el diálogo; el resultado decide si llama DELETE.
- **Propiedades:** `content`, `title`, `actions`; callbacks; `onRefresh`.
- **Alternativas:** página para formulario largo; diálogo para decisión breve;
  banner persistente para aviso crítico.
- **Error común:** no manejar `null` cuando el usuario cierra el diálogo.
- **Ejercicio:** confirma el vaciado del carrito con cancelar y aceptar.

### `Badge`, `Chip` y `ExpansionTile`

- **Qué hacen:** `Badge` indica una cantidad; `Chip` muestra categoría/estado;
  `ExpansionTile` revela detalle plegable.
- **Dónde:** contador del carrito (`catalog_screen.dart:101`), rol en home,
  estado de pedido y detalle expandible.
- **Ejemplo real:** `Badge(label: Text('$itemCount'), child:
  Icon(Icons.shopping_cart_outlined))`.
- **Explicación:** el badge dibuja la cifra; el icono representa el carrito.
- **Propiedades:** `label`, `isLabelVisible`, `child`; `Chip.label/avatar`;
  `ExpansionTile.title/children`.
- **Alternativas:** texto normal para un estado largo; página de detalles si el
  contenido expandido es extenso.
- **Error común:** que la cifra no refleje el estado actualizado o que un
  contenido expandido haga la pantalla demasiado larga.
- **Ejercicio:** convierte el chip de estado en color por estado del pedido.

## 6. Navegación y rutas

### `Navigator` y `MaterialPageRoute`

- **Qué hacen:** mantienen la pila de pantallas; la ruta Material añade una
  pantalla y animación nativas de plataforma.
- **Dónde:** login a home/registro; home a módulos; inventario a formulario;
  POS a factura; carrito a pedidos.
- **Ejemplo real:**

  ```dart
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => HomeScreen(name: name, email: email, roleId: roleId),
    ),
  );
  ```

- **Línea por línea:** obtiene el navegador del árbol; reemplaza la pantalla de
  login; crea una ruta; construye home con los datos del usuario.
- **Propiedades/operaciones:** `push`, `pushReplacement`, `pushAndRemoveUntil`,
  `pop`; `builder`.
- **Alternativas:** `go_router` para rutas declarativas, URL web, deep links y
  guards; navegación actual es suficiente para el conjunto pequeño de rutas.
- **Error común:** usar `BuildContext` después de `await` sin comprobar
  `mounted`, o dejar login en la pila después de autenticarse.
- **Ejercicio:** abre formulario de producto y devuelve `true` al guardar para
  recargar la lista.

## 7. Estado

### `StatelessWidget`, `StatefulWidget`, `State` y `setState`

- **Qué hacen:** un widget sin estado local variable es `StatelessWidget`;
  uno con ciclo de vida/estado local es `StatefulWidget`; su objeto `State`
  guarda valores; `setState` notifica que hay que reconstruir.
- **Dónde:** `FerreteriaApp`, home y `ProductPhoto` son sin estado; login,
  catálogo, inventario, POS, factura y pedidos son con estado.
- **Ejemplo real:** `setState(() => _loading = true);`.
- **Explicación:** anuncia un cambio; asigna el indicador; Flutter vuelve a
  ejecutar `build` y refleja el spinner.
- **Propiedades/conceptos:** `widget` lleva parámetros inmutables;
  `State` conserva valores; `initState` inicializa; `dispose` libera;
  `mounted` impide operar tras desmontaje.
- **Alternativas:** `ChangeNotifier`/Provider, Riverpod o Bloc cuando el estado
  se comparte entre muchas pantallas o requiere coordinación compleja.
- **Error común:** llamar `setState` luego de `await` sin verificar `mounted`,
  o poner estado global en una pantalla sin propietario claro.
- **Ejercicio:** rastrea qué estados de carrito sobreviven al salir del
  catálogo. Diseña una opción para persistirlo.

### `GlobalKey<FormState>` y ciclo de vida

- **No son widgets visuales:** la `Key` identifica un elemento; la clave del
  formulario expone métodos de validación. `initState`, `dispose` y `mounted`
  son parte del ciclo de vida.
- **Dónde:** `auth_screens.dart:15,21,63`; controladores en formularios;
  `catalog_screen.dart:29,35`.
- **Ejemplo real:** `_formKey.currentState!.validate()`.
- **Explicación:** busca el `FormState` asociado; llama a validadores; el
  resultado permite o detiene la solicitud.
- **Propiedades:** las claves se colocan en `key`; `GlobalKey` permite acceder
  al estado, pero debe usarse solo cuando hace falta.
- **Alternativas:** control de formulario local explícito o claves locales
  para listas dinámicas.
- **Error común:** construir una `GlobalKey` nueva dentro de cada `build`.
- **Ejercicio:** identifica qué controladores deben liberarse en `dispose`.

## 8. Asincronía y datos

### `Future`, Dio, `Dio` y widgets de progreso

- **Qué hacen:** un `Future` representa una operación que terminará luego;
  Dio ejecuta HTTP; `CircularProgressIndicator` y
  `LinearProgressIndicator` presentan carga.
- **Dónde:** `ApiClient` y funciones `_login`, `_search`, `_load`, `_charge`,
  `_createOrder`; indicadores en formularios y listas.
- **Ejemplo real:**

  ```dart
  final response = await ApiClient.instance.dio.get<List<dynamic>>(
    '/catalogo/productos',
  );
  setState(() => _products = response.data!
      .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList());
  ```

- **Línea por línea:** espera GET; solicita JSON como lista; interpreta cada
  objeto con el modelo; actualiza estado y pantalla.
- **Propiedades/contexto:** `await`, `try/catch/finally`, timeout de Dio,
  `queryParameters`, `data`, `headers`; los indicadores no hacen la solicitud,
  solo visualizan su estado.
- **Alternativas:** `FutureBuilder` para una consulta cuyo Future se administra
  desde el build; el proyecto usa funciones explícitas y estados porque debe
  permitir recargar, capturar errores y mutar datos.
- **Error común:** iniciar el Future dentro de `build`, duplicando peticiones;
  olvidar `finally` y dejar la carga bloqueada.
- **Ejercicio:** dibuja los estados loading, éxito vacío, éxito con datos y
  error de la consulta de catálogo.

### `Future.wait`, `Timer` e interceptores

- **Qué hacen:** `Future.wait` lanza cargas independientes en paralelo;
  `Timer` agrupa escritura rápida antes de buscar; `InterceptorsWrapper`
  agrega lógica común a peticiones HTTP.
- **Dónde:** `inventory_screen.dart:28`, `catalog_screen.dart:43`,
  `core/api_client.dart:20`.
- **Ejemplo real:** `Future.wait([GET productos, GET categorías, GET
  ubicaciones])`.
- **Explicación:** reúne futures; evita esperar secuencialmente; solo continúa
  cuando concluyen.
- **Propiedades:** lista de operaciones; duración y cancelación del `Timer`;
  callbacks `onRequest`, `onResponse`, `onError`.
- **Alternativas:** llamadas secuenciales si una depende de la anterior;
  debounce especializado si el flujo crece.
- **Error común:** no cancelar el Timer al destruir pantalla, o ignorar que
  `Future.wait` falla si una llamada del grupo falla.
- **Ejercicio:** añade un debounce de 300 ms al buscador del POS y cancélalo en
  `dispose`.

### `Image.asset`, `Image.network` y constructores de error/carga

- **Qué hacen:** cargan una imagen empaquetada con la aplicación o desde URL;
  los builders personalizan carga y error.
- **Dónde:** `Image.asset` para logo; `Image.network` en
  `ProductPhoto`.
- **Ejemplo real:** `Image.network(imageUrl, fit: fit, loadingBuilder: ...,
  errorBuilder: ...)`.
- **Línea por línea:** obtiene imagen remota; ajusta recorte; muestra progreso;
  ante fallo presenta placeholder.
- **Propiedades:** `fit`, `width`, `height`, `loadingBuilder`,
  `errorBuilder`, `semanticLabel`.
- **Alternativas:** cache de imágenes para catálogos usados repetidamente;
  asset para recursos de marca que no cambian.
- **Error común:** no prever URL vacía, error de red o tamaño sin límite.
- **Ejercicio:** agrega texto semántico al logo y comprueba lector de pantalla.

## 9. Estilo y tema

### `ThemeData`, `ColorScheme`, `TextStyle` y `InputDecoration`

- **Qué hacen:** definen lenguaje visual global, paleta, tipografía puntual y
  presentación de controles.
- **Dónde:** `main.dart:17-65`; `TextStyle` en catálogo/home.
- **Ejemplo real:** `Theme.of(context).textTheme.titleLarge?.copyWith(...)`.
- **Explicación:** lee el tema heredado; selecciona estilo semántico; cambia
  solo peso/color, preservando el resto.
- **Propiedades:** colores `primary/secondary/surface`; estilos de texto;
  bordes, relleno, etiqueta e iconos del campo.
- **Alternativa:** estilos repetidos en cada widget se pueden centralizar en el
  tema; valores únicos pueden ser inline.
- **Error común:** codificar el mismo estilo en toda pantalla y hacer difícil
  mantener consistencia.
- **Ejercicio:** define un estilo compartido para precios y aplícalo a
  catálogo, carrito y POS.

### Temas y decoraciones Material

- **Elementos:** `AppBarTheme`, `InputDecorationTheme`, `CardThemeData`,
  `FilledButtonThemeData`, `BoxDecoration`, `OutlineInputBorder`,
  `RoundedRectangleBorder`, `BorderSide`, `Color`, `EdgeInsets`.
- **Dónde:** `main.dart:25-64`, tarjetas y banners de catálogo/home.
- **Ejemplo real:** `CardThemeData(color: Colors.white, elevation: 1,
  shape: RoundedRectangleBorder(...))`.
- **Explicación:** aplica fondo; configura elevación; instala forma común para
  tarjetas.
- **Propiedades:** color, elevación, forma, radio, borde, relleno.
- **Alternativa:** estilo local si es una excepción justificada; tema común
  cuando se comparte.
- **Error común:** creer que toda clase de estilo es un widget. Estas clases
  describen widgets, pero no aparecen como nodos visuales del árbol.
- **Ejercicio:** cambia solo el radio del tema de tarjeta y localiza todas las
  pantallas afectadas.

### `Icon`, `IconButton`, `CircleAvatar` y `ProductPhoto`

- **Qué hacen:** presentan símbolos; permiten tocar un símbolo; muestran una
  insignia circular; y resuelven imagen de producto más placeholder.
- **Dónde:** app completa; `ProductPhoto` en `lib/widgets/product_photo.dart`.
- **Fragmento real:** `ProductPhoto(url: product.photoUrl, fit:
  BoxFit.cover, iconSize: 48)`.
- **Explicación:** la URL puede ser nula; `fit` define encuadre; el tamaño
  afecta al icono de fallback.
- **Propiedades:** `Icon.size/color`; `IconButton.onPressed/tooltip`;
  `CircleAvatar.child/backgroundColor`; `ProductPhoto.url/fit/iconSize`.
- **Alternativas:** `Image` directa si no se requieren estados de error/carga;
  texto en lugar de icono si hay ambigüedad.
- **Error común:** icono sin etiqueta accesible, o asumir que la URL remota
  siempre responde.
- **Ejercicio:** añade placeholder y texto accesible a la imagen del producto.

## 10. Widgets personalizados del proyecto

| Widget/clase | Tipo | Uso |
|---|---|---|
| `FerreteriaApp` | `StatelessWidget` | Arranque, tema y `LoginScreen` (`main.dart:9`). |
| `LoginScreen`, `RegisterScreen` | Stateful | Formularios de autenticación (`auth_screens.dart:7,171`). |
| `HomeScreen` | Stateless | Inicio y menú condicionado por rol (`home_screen.dart:10`). |
| `CatalogScreen` | Stateful | Catálogo cliente o búsqueda de empleado (`catalog_screen.dart:10`). |
| `InventoryScreen` | Stateful | Pestañas de inventario, categorías y ubicaciones (`inventory_screen.dart:7`). |
| `ProductFormScreen` | Stateful | Alta/edición de producto (`inventory_screen.dart:283`). |
| `_CatalogEntryDialog` | Stateful | Alta/edición de categoría o ubicación (`inventory_screen.dart:513`). |
| `_ErrorState`, `_EmptyState` | Stateless privados | Estados de error y vacío (`inventory_screen.dart:614,639`). |
| `PosScreen` | Stateful | Búsqueda, carrito y cobro (`pos_screen.dart:7`). |
| `InvoiceScreen` | Stateful | Vista y reintento de datos de factura (`invoice_screen.dart:8`). |
| `OrderCartScreen` | Stateful | Carrito y alta del pedido (`order_screens.dart:13`). |
| `CustomerOrdersScreen`, `StaffOrdersScreen` | Stateful | Historial del cliente y cola del personal (`order_screens.dart:214,375`). |
| `_ErrorPanel` | Stateless privado | Mensaje y reintento de listas (`order_screens.dart:512`). |
| `ProductPhoto` | Stateless | Imagen remota con progreso y placeholder (`widgets/product_photo.dart:3`). |
| `OrderCartLine`, `_CartLine`, `_HomeAction` | Clases de datos, **no widgets** | Representan línea de carrito o acción de home (`order_screens.dart:6`, `pos_screen.dart:319`, `home_screen.dart:186`). |
| `Product` | Modelo, **no widget** | Convierte JSON de producto (`models/product.dart:1`). |

### Ficha: `ProductPhoto`

- **Qué hace:** unifica foto de producto, estado de carga y fallback si la URL
  falta o falla.
- **Dónde:** `lib/widgets/product_photo.dart:3-51`; catálogo e inventario.
- **Ejemplo y explicación:** `Image.network(imageUrl, fit: fit,
  loadingBuilder: ..., errorBuilder: ...)`: solicita la foto; decide su
  encuadre; enseña indicador mientras carga; usa icono si ocurre error.
- **Propiedades:** `url`, `fit`, `iconSize`.
- **Por qué aquí:** evita repetir en catálogo e inventario el tratamiento de
  fotos ausentes o inválidas. Alternativa: imagen simple si el backend
  garantizara siempre una URL accesible.
- **Error común:** ocultar todos los errores como si fueran el mismo; en
  producción conviene registrar fallos de imagen si afectan soporte.
- **Ejercicio:** añade una variante compacta para miniaturas y prueba URL vacía,
  válida y rota.

### Ficha: estados vacíos y de error

- **Clases:** `_EmptyState`, `_ErrorState`, `_ErrorPanel`.
- **Qué hacen:** presentan mensajes contextualizados y, en error, un reintento.
- **Dónde:** inventario y pedidos, líneas indicadas en la tabla.
- **Ejemplo real:** `_ErrorPanel(message: _error!, onRetry: _loadOrders)`.
- **Línea por línea:** transmite el texto actual; pasa una función que reintenta;
  el panel representa ambos de forma uniforme.
- **Propiedades:** texto del mensaje, callback de reintento, `child`.
- **Alternativa:** `Text` inline para una sola etiqueta; componente compartido
  para estados recurrentes.
- **Error común:** mostrar pantalla vacía sin diferenciar “sin datos” de “falló
  la API”.
- **Ejercicio:** diseña estado vacío del carrito con acción de regresar al
  catálogo.

### Widgets de PDF de `package:pdf`

`pw.Document`, `pw.Page`, `pw.Padding`, `pw.Column`, `pw.Text`, `pw.TableHelper`,
`pw.Spacer` y `pw.Align` componen un documento que luego `Printing` muestra,
guarda o imprime (`invoice_screen.dart:38-103`). Se parecen a Flutter en sus
nombres y composición, pero **no forman parte del árbol de widgets visible de
Flutter**. El PDF tiene su propio contexto y tipos (`pw.*`).

## Fichas compactas de widgets complementarios

Las secciones previas explican con más detalle los patrones compuestos. Esta
tabla completa los widgets visibles usados en `lib/`; cada entrada identifica
ubicación, función, propiedades, alternativa, error frecuente y un ejercicio.
Los ejemplos literales están en el archivo indicado. Fragmentos reales:

```dart
const Tab(text: 'Productos', icon: Icon(Icons.inventory_2_outlined))
const CircularProgressIndicator(strokeWidth: 2)
ListTile(title: Text(product.name), subtitle: Text(product.code))
```

`Tab` aporta una etiqueta e icono; el indicador representa trabajo en curso;
`ListTile` presenta título y subtítulo. En el primero el valor de `text` es la
etiqueta, `icon` añade símbolo; en el segundo `strokeWidth` controla el grosor;
en el tercero los dos hijos describen la fila.

| Widget | Dónde aparece | Función y propiedades clave | Alternativa | Error habitual | Mini ejercicio |
|---|---|---|---|---|---|
| `Text` | Todas las pantallas | Muestra texto; `data`, `style`, `maxLines`, `overflow`, `textAlign`. Ej.: `catalog_screen.dart:134`. | `SelectableText` si debe copiarse. | Texto largo excede la tarjeta. | Prueba nombre largo con elipsis. |
| `Card` | Catálogo, inventario, home, factura y pedidos | Agrupa contenido; `child`, `elevation`, `shape`, `clipBehavior`. | `Container` sin semántica de tarjeta. | Anidar tarjetas sin jerarquía. | Presenta una línea de pedido como tarjeta. |
| `ListTile` | Home, inventario, búsqueda interna y pedidos | Fila estándar; `leading`, `title`, `subtitle`, `trailing`, `onTap`. | `Row` personalizada. | `trailing` ocupa más ancho del disponible. | Agrega precio a una fila de inventario. |
| `Tab` | `inventory_screen.dart:143-145` | Una opción de pestaña; `text`, `icon`, `child`. | Botones segmentados para filtros. | No emparejar cada Tab con una página. | Añade la cuarta pestaña y su contenido. |
| `TabBar` | `inventory_screen.dart:140-146` | Selector de secciones; `tabs`, `isScrollable`, controlador heredado. | Navegación principal para destinos. | Usarlo para una acción puntual. | Cambia orden y revisa `TabBarView`. |
| `TabBarView` | `inventory_screen.dart:153` | Página asociada a pestaña; `children`, `controller`. | `PageView` cuando no hay pestañas rotuladas. | Cantidad u orden distinto al TabBar. | Añade un estado vacío como página. |
| `CircularProgressIndicator` | Formularios y estados de carga | Progreso circular; `strokeWidth`, `value`, `color`. | `LinearProgressIndicator`. | No reservar tamaño y producir saltos. | Encierra spinner de botón en `SizedBox`. |
| `LinearProgressIndicator` | Catálogo y POS | Progreso horizontal mientras consulta; `value`, `color`. | Indicador circular en acción compacta. | Dejarlo visible al terminar. | Actívalo solo durante búsqueda. |
| `Image.asset` | Logo en login, home y catálogo | Carga imagen empaquetada; `width`, `height`, `fit`. | `Image.network` para contenido variable remoto. | Olvidar registrar el asset en pubspec. | Cambia temporalmente su tamaño. |
| `Image.network` | `ProductPhoto`, `product_photo.dart:23` | Descarga foto; `fit`, `loadingBuilder`, `errorBuilder`. | Asset local o caché de imágenes. | No prever URL nula/rota. | Simula URL inválida y revisa fallback. |
| `Badge` | `catalog_screen.dart:101` | Muestra conteo junto al carrito; `label`, `child`, `isLabelVisible`. | `Chip` para etiqueta verbal. | Mostrar cero aunque el diseño lo oculte. | Oculta badge al vaciar carrito. |
| `Chip` | Rol y estado de pedido | Etiqueta breve; `label`, `avatar`, color. | Texto normal para contenido largo. | Insertar un párrafo en espacio compacto. | Colorea cada estado de pedido. |
| `CircleAvatar` | Home, búsqueda y pedidos | Contenedor circular para icono/foto; `child`, `backgroundColor`, `radius`. | `Container` para otras formas. | No respetar proporción de imagen. | Cambia icono por estado. |
| `ColoredBox` | `product_photo.dart:27,42` | Pinta fondo; `color`, `child`. | `Container` si requiere más propiedades. | Esperar que recorte al hijo. | Cambia fondo del placeholder. |
| `Divider` | POS y factura | Línea separadora; `height`, `thickness`, `indent`, `color`. | `SizedBox` si solo se requiere espacio. | Sustituir jerarquía visual por muchas líneas. | Separa total de impuestos. |
| `SnackBar` | Login, inventario, pedidos y carrito | Mensaje temporal; `content`, `duration`, `action`. | Banner o diálogo para información persistente. | Usarlo para errores largos sin acción. | Notifica al agregar producto. |
| `AlertDialog` | Confirmación CRUD | Diálogo modal; `title`, `content`, `actions`. | Página para formulario extenso. | No gestionar cierre/cancelación. | Cancelar borrado y comprobar que no ocurre. |
| `DropdownMenuItem<T>` | Filtros y tipo de cliente | Empareja valor tipado con `child`. | Lista filtrable para catálogos grandes. | Valores duplicados o incompatibles. | Añade búsqueda por marca. |
| `OutlinedButton` | Reintento de pedidos | Acción secundaria; `onPressed`, `child`, `style`. | Filled para acción primaria. | Mismo énfasis que acción principal. | Compara jerarquía con Filled. |
| `TextButton` | Cancelar/reintentar y diálogos | Acción ligera; `onPressed`, `child`. | Outlined si necesita más énfasis. | Usarlo para acción destructiva sin confirmación. | Añade cancelación a un diálogo. |
| `IconButton` | Editar, eliminar, carrito, cerrar, visibilidad | Acción compacta; `icon`, `onPressed`, `tooltip`. | Botón con texto si el icono es ambiguo. | Sin tooltip/etiqueta accesible. | Agrega tooltip a acción de POS. |
| `FilledButton` | Guardar, cobrar, confirmar, login | Acción principal; `onPressed` nulo desactiva; `child`, `style`. | Outlined para secundaria. | Permitir doble envío. | Bloquéalo mientras `_loading`. |
| `FilledButton.icon` | Catálogo y POS | Acción primaria más símbolo; `icon`, `label`, `onPressed`. | IconButton si la acción es universal. | Etiqueta se desborda en móvil. | Prueba botón a 320 px. |
| `FilledButton.tonal`, `.tonalIcon` | Estados y agregar al carrito | Variantes de menor énfasis; callback, icono y etiqueta. | Filled sólido para acción prioritaria. | Elegir énfasis sin considerar contexto. | Decide estilo para “Entregado”. |
| `OutlinedButton.icon` | Acceso a registro | Acción con contorno e icono; `icon`, `label`, `onPressed`. | TextButton.icon. | Icono no representa la acción. | Cambia icono y evalúa legibilidad. |
| `SafeArea` | Login, registro, home, carrito | Respeta insets del dispositivo; `minimum`, `top`, `bottom`. | Padding explícito en diseño fijo. | Anidar SafeArea y duplicar márgenes. | Prueba con inset superior. |
| `SingleChildScrollView` | Login y registro | Desplaza un único hijo grande; `padding`, `scrollDirection`. | ListView para colecciones. | Usarlo para 1000 filas no virtualizadas. | Reduce altura y conserva acceso al botón. |
| `RefreshIndicator` | Listas de inventario/pedidos | Gesto de refresco; `onRefresh` devuelve Future. | Botón de actualizar. | Hijo no desplazable/no siempre scrollable. | Muestra loading al refrescar. |
| `ExpansionTile` | “Mis pedidos” | Expande hijos; `title`, `leading`, `children`, callback. | Ruta de detalle separada. | Repetir cargas sin estado de espera/error. | Añade loading de detalle visible. |
| `Align` | Alinear acción de pedido y PDF | Alinea hijo; `alignment`, `child`. | Row con `mainAxisAlignment`. | Creer que limita dimensiones del hijo. | Alinea acción a la derecha. |
| `Spacer` | PDF | Ocupa espacio flexible dentro de Flex; `flex`. | SizedBox fijo. | Usarlo fuera de Row/Column. | Empuja resumen abajo en una columna. |
| `ClipRRect` | Foto del inventario | Recorta a esquinas; `borderRadius`, `child`. | ClipOval para círculo. | Creer que decoración del padre recorta imagen. | Cambia radio de miniatura. |
| `ConstrainedBox` | Login/registro | Aplica límites de tamaño; `constraints`, `child`. | SizedBox de tamaño fijo. | Confundir máximo con ancho obligatorio. | Compara ancho máximo 420. |
| `Container` | Banner, bienvenida y logo | Combina tamaño, fondo, padding y forma. | Padding o ColoredBox si solo hace una tarea. | Encadenar containers innecesarios. | Simplifica un Container solo de padding. |
| `Padding` | Formularios, tarjetas, mensajes | Espacio interior; `padding`, `child`. | Container con padding. | Confundir padding con margin. | Ajusta separación de campos. |
| `SizedBox` | Separaciones y tamaño de iconos | Dimensión fija o hueco; `width`, `height`, `child`. | Spacer para espacio flexible. | Usar altura fija para texto variable. | Sustituye un hueco por Spacer. |
| `Row` | Controles del carrito/resúmenes | Layout horizontal; `children`, alineación. | Wrap si debe saltar de línea. | Overflow con ancho insuficiente. | Usa Expanded para nombre largo. |
| `Column` | Formularios/tarjetas | Layout vertical; `children`, eje principal/cruzado. | ListView si necesita scroll propio. | Overflow vertical con contenido largo. | Escoge quién debe desplazarse. |
| `Expanded` | Listados, grid y carrito | Ocupa espacio restante en Flex; `flex`, `child`. | Flexible si no debe llenarlo. | Usarlo fuera de Row/Column/Flex. | Resuelve fila con texto extenso. |
| `Wrap` | Acciones CRUD en filas | Envuelve hijos a otra línea; spacing, runSpacing. | Row si siempre caben. | No prever la altura adicional. | Reduce ancho de acciones del inventario. |
| `Center` | Loading, login y estados vacíos | Centra hijo; `child`, `widthFactor`, `heightFactor`. | Align para posición específica. | El padre no ocupa el espacio esperado. | Centra mensaje de catálogo vacío. |
| `LayoutBuilder` | Cuadrícula catálogo | Da restricciones locales al builder; `constraints`. | MediaQuery para tamaño de ventana. | Mirar ancho global en panel angosto. | Simula grid dentro de panel. |
| `DefaultTabController` | Inventario | Mantiene selección de tabs; `length`, `child`. | TabController para control explícito. | Length incorrecto. | Agrega/retira pestaña emparejada. |
| `Scaffold` | Pantallas principales | Estructura material; `appBar`, `body`, `floatingActionButton`. | Layout propio para casos no estándar. | Poner un Scaffold por sección pequeña. | Identifica raíz de una ruta. |
| `AppBar` | Pantallas principales | Cabecera; `title`, `actions`, `bottom`. | SliverAppBar en listas colapsables. | Título largo compite con acciones. | Ajusta título para móvil. |
| `MaterialApp` | `main.dart:14` | Raíz de navegación/tema; `theme`, `home`, `title`. | CupertinoApp para app iOS nativa. | Anidar MaterialApp sin motivo. | Localiza cómo llega Theme a un campo. |
| `StatelessWidget` | App, home, ProductPhoto, error | Widget sin estado mutable local; constructor/child. | Stateful si debe recordar cambios. | Guardar cambio en variable local de build. | Decide si un banner necesita State. |
| `StatefulWidget` | Formularios y pantallas de datos | Declara widget con objeto `State`; `key`. | Stateless + estado en padre para componentes presentacionales. | Poner mutabilidad dentro de la configuración widget. | Identifica dueño del carrito. |

## Widgets/tecnologías que no se usan

- No hay `Provider`, `Riverpod`, `Bloc` ni `ChangeNotifier`: el estado de cada
  pantalla usa `State` y `setState`.
- No hay `FutureBuilder` o `StreamBuilder`: la app ejecuta peticiones desde
  métodos asíncronos y guarda loading/error/datos en `State`.
- No hay `Stack`, `Positioned`, `CustomPainter`, `CupertinoApp` ni `Scaffold`
  anidados como arquitectura de navegación.
- `Navigator`, `MaterialPageRoute`, `showDialog`, `Timer`, `Dio`,
  `FlutterSecureStorage` y `Printing` son APIs/objetos, no widgets.

## Ruta de lectura sugerida del inventario

Empieza con `MaterialApp` → `Scaffold` → `Column/Row` → campos y botones →
listas → estado (`StatefulWidget`) → HTTP (`Dio`) → rutas → componentes
personalizados → PDF.
