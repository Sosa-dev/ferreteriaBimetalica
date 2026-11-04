# 02. Ruta de aprendizaje de Flutter: cuatro semanas

Pensada para estudiar una hora diaria y practicar en la app de Ferretería
Bimetálica. Cada día sigue el ciclo: leer el fragmento, explicar su propósito
con palabras propias, ejecutar la app y realizar el mini reto. No es necesario
terminar una función nueva para aprender de ella.

## Semana 1 — Base de Dart y composición visual

| Día | Tema | Lectura y práctica |
|---|---|---|
| 1 | Estructura Flutter y punto de entrada | Lee `lib/main.dart`. Explica `main()`, `runApp`, `FerreteriaApp` y `MaterialApp`. Dibuja esos cuatro niveles. |
| 2 | Widget tree y `build` | Lee `HomeScreen.build`. Dibuja `Scaffold → AppBar/body → hijos`. Distingue una clase widget de un objeto de datos. |
| 3 | Layout básico | Practica `Column`, `Row`, `Padding`, `SizedBox`, `Center` y `Expanded` con la tarjeta de bienvenida de home. |
| 4 | Dimensiones y adaptabilidad | Lee `LayoutBuilder` en catálogo y `ConstrainedBox` de login. Prueba 320, 600 y 1000 px; anota cómo cambia la cuadrícula. |
| 5 | Texto, iconos y estilo | Inspecciona `Text`, `TextStyle`, `Icon`, `CircleAvatar`, `Card`, `BoxDecoration` y el tema. Cambia de manera local el estilo de una tarjeta. |
| 6 | Scroll y listas | Compara `ListView`, `ListView.builder`, `GridView.builder` y `SingleChildScrollView`. Decide cuál usarías para 10 frente a 10 000 productos. |
| 7 | Repaso semanal | Sin mirar el código, dibuja login y home. Después valida el dibujo contra `auth_screens.dart` y `home_screen.dart`. |

## Semana 2 — Formularios, interacción y estado

| Día | Tema | Lectura y práctica |
|---|---|---|
| 8 | `TextField` frente a `TextFormField` | Compara el buscador de catálogo con los campos de login. Anota cuándo se ejecuta `validator`. |
| 9 | `Form` y `GlobalKey` | Sigue el camino desde `_formKey.currentState!.validate()` hasta los validadores de correo y contraseña. Crea un validador mental para código de producto. |
| 10 | Controladores y ciclo de vida | Revisa `TextEditingController`, `initState` y `dispose` en registro y producto. Haz un inventario de controladores y quién los libera. |
| 11 | Botones y feedback | Recorre `FilledButton`, `OutlinedButton`, `TextButton`, `IconButton`, `SnackBar` y `AlertDialog`. Distingue acción primaria, secundaria y destructiva. |
| 12 | Estado local y `setState` | Sigue `_loading` en login y `_cart` en catálogo. Escribe qué cambia antes de HTTP, al éxito y al error. |
| 13 | Identidad y lifecycle | Estudia `StatefulWidget`, `State`, `widget`, `mounted` e `initState`. Busca por qué se comprueba `mounted` después de `await`. |
| 14 | Repaso semanal | Haz una validación o mensaje temporal en una copia conceptual del formulario. Repite el flujo sin editar el proyecto principal. |

## Semana 3 — Red, modelos y rutas

| Día | Tema | Lectura y práctica |
|---|---|---|
| 15 | JSON y tipos | Lee `Product.fromJson`. Traza un campo del JSON `precio_venta` a `double` y observa qué ocurre si llega inválido. |
| 16 | Cliente HTTP Dio | Lee `core/api_client.dart`: `BaseOptions`, tiempos límite, interceptor y conversión de errores. Señala dónde se toma el host de API. |
| 17 | Request y query params | Sigue `_search` en catálogo y `_findProducts` en POS. Escribe método HTTP, path, query y forma de respuesta. |
| 18 | Autenticación | Sigue login: formulario → `POST /auth/login` → token → almacenamiento seguro → navegación. Diferencia 401 de 403. |
| 19 | CRUD e inventario | Sigue `_load` y `_save` de inventario. Explica por qué se consultan productos, categorías y ubicaciones; compara POST con PUT. |
| 20 | Navegación y resultado de ruta | Revisa `Navigator.push`, `pushReplacement`, `pushAndRemoveUntil` y `pop(true)`. Dibuja la pila al abrir y guardar un producto. |
| 21 | Repaso semanal | Haz una tabla pantalla–endpoint–modelo–estado. Incluye catálogo, inventario y login. |

## Semana 4 — Flujos completos, pruebas y criterio profesional

| Día | Tema | Lectura y práctica |
|---|---|---|
| 22 | Carrito de pedido | Traza `Product` → `OrderCartLine` → mapa `producto_id/cantidad` en `_createOrder`. Identifica qué calcula servidor y qué presenta la app. |
| 23 | Pedidos y refresco | Lee `CustomerOrdersScreen` y `StaffOrdersScreen`. Distingue loading, error, vacío, lista y detalle expandido. |
| 24 | POS y factura | Sigue el carrito de ventas hasta `POST /ventas`; compara los importes de vista previa con los que responde la API. |
| 25 | Reutilización | Analiza `ProductPhoto`, `_ErrorPanel`, `_EmptyState` y `_ErrorState`. Decide qué componentes convendría mover a `widgets/`. |
| 26 | Pruebas de widget y modelo | Lee `test/product_test.dart`, `test/widget_test.dart` e `inventory_screen_test.dart`. Explica qué prueba cada expectativa y qué no puede probar. |
| 27 | Accesibilidad, responsive y errores | Recorre labels, tooltips, mensajes, elipsis, `isExpanded`, layout adaptativo y callbacks deshabilitados. Comprueba el desbordamiento del formulario como caso de regresión. |
| 28 | Evaluación final | Explica de memoria el flujo de pedido completo y dibuja el árbol de catálogo. Usa el checklist de `05_repaso.md` para elegir el siguiente tema. |

## Cómo practicar de forma deliberada

1. Antes de ejecutar, predice lo que verás y escribe el estado esperado.
2. Cambia una sola cosa en una rama de práctica.
3. Ejecuta análisis y pruebas existentes.
4. Compara tu hipótesis con lo observado.
5. Deshaz mentalmente el cambio y explica por qué la arquitectura eligió ese
   patrón, qué alternativa existe y qué costo tiene.

## Qué viene después de estas cuatro semanas

- Separar presentación, lógica de pantalla y acceso a datos en servicios y
  repositorios.
- Introducir una solución de estado compartido (por ejemplo, Riverpod) cuando
  haya una necesidad real entre pantallas.
- Tipar pedido, líneas, factura y usuario en vez de propagar mapas dinámicos.
- Añadir pruebas de API/contratos y una prueba de integración contra FastAPI.
- Estudiar navegación declarativa, accesibilidad, internacionalización y
  observabilidad.
