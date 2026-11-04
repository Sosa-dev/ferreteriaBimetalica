# 05. Material de repaso

## Glosario

| Término | Explicación sencilla | Ejemplo en el proyecto |
|---|---|---|
| Widget | Pieza de interfaz o descripción de cómo se ve una parte de la app. Puede ser visible o estructural. | `Scaffold`, `Text`, `ProductPhoto`. |
| Widget tree | Árbol que representa widgets anidados: cada `child` o elemento de `children` forma niveles. | Login: `Scaffold → Form → Column → TextFormField`. |
| BuildContext | Referencia a la ubicación de un widget dentro del árbol; permite obtener tema, navegar y mostrar mensajes. | `Theme.of(context)`, `Navigator.of(context)`. |
| `build` | Método que describe la interfaz a partir del estado y las propiedades actuales. Flutter puede ejecutarlo muchas veces. | Cada pantalla principal. |
| `StatelessWidget` | Widget cuyos datos no cambian por estado interno mantenido en esa instancia. | `FerreteriaApp`, `HomeScreen`, `ProductPhoto`. |
| `StatefulWidget` | Widget que tiene un objeto `State` asociado capaz de cambiar. | `CatalogScreen`, `PosScreen`. |
| `State` | Objeto que conserva valores mutables de un widget y participa en su ciclo de vida. | `_CatalogScreenState._products`. |
| Estado | Datos que pueden cambiar y afectan la UI. | `_loading`, `_error`, `_cart`. |
| `setState` | Informa a Flutter de que cambió estado y necesita reconstruir esa parte. | Cambiar `_loading` al iniciar una petición. |
| `widget` | Instancia del `StatefulWidget` que entrega parámetros inmutables a su `State`. | `widget.product`, `widget.employeeMode`. |
| `Key` | Identidad que ayuda a Flutter a asociar elementos entre reconstrucciones. | `GlobalKey<FormState>` para validar un Form. |
| `GlobalKey` | Clave global que permite acceder al estado de un widget o mantener identidad especial. Costosa; se usa con moderación. | `_formKey.currentState!.validate()`. |
| `BuildContext` heredado | Contexto desde el cual se busca un valor provisto por antecesores, como Theme o Navigator. | `Theme.of(context)`. |
| `child` | El widget hijo único que un contenedor recibe. | `Padding(child: Column(...))`. |
| `children` | Colección de widgets hijos. | `Column(children: [...])`. |
| `Stateful lifecycle` | Etapas de vida de un estado. | `initState`, `build`, `dispose`. |
| `initState` | Se llama una vez cuando se crea el estado; adecuado para inicializar/cargar datos. | Cargas iniciales de catálogo/pedidos. |
| `dispose` | Se llama al retirar el estado; liberar controladores, timers y recursos. | Cierre de `TextEditingController`. |
| `mounted` | Indica si ese estado sigue dentro del árbol. | Guard tras `await` antes de `setState`. |
| `Future` | Representa un resultado que llegará más adelante, por ejemplo una respuesta HTTP. | `Future<void> _loadOrders()`. |
| `async` / `await` | Sintaxis para esperar operaciones asíncronas sin bloquear el hilo de interfaz. | `await dio.get(...)`. |
| `FutureBuilder` | Widget que representa un Future mediante estados de espera/éxito/error. | No se usa en esta app; el estado se maneja manualmente. |
| `Stream` / `StreamBuilder` | Flujo de múltiples valores a lo largo del tiempo y widget que escucha ese flujo. | No se usa en el proyecto actual. |
| HTTP | Protocolo de solicitud/respuesta usado por app y API. | GET productos, POST pedidos. |
| Endpoint | Dirección y método de una operación HTTP en la API. | `GET /pedidos`. |
| JSON | Formato de texto para intercambiar objetos y listas. | Respuesta que se convierte en `Product`. |
| Modelo | Tipo Dart que representa datos del dominio y puede interpretar JSON. | `Product.fromJson`. |
| DTO | Objeto de transferencia de datos para enviar/recibir un contrato. | Payload `{producto_id, cantidad}` del pedido. |
| Dio | Paquete HTTP utilizado para enviar requests y procesar respuestas/errores. | `ApiClient.instance.dio`. |
| Interceptor | Función común que procesa una solicitud/respuesta de Dio. | Agrega JWT a solicitudes. |
| JWT | Token firmado que prueba identidad/autorización ante FastAPI. | `jwt_token` almacenado seguro. |
| `mounted` después de `await` | Protección porque la pantalla pudo cerrarse mientras la red respondía. | Evita actualizar una pantalla destruida. |
| Debounce | Espera una breve pausa entre pulsaciones antes de iniciar búsqueda. | Catálogo espera 350 ms. |
| Rebuild | Reconstrucción de widgets dependientes de datos cambiados. | `setState` repinta contador del carrito. |
| Inmutabilidad | No modificar una instancia luego de crearla. Facilita razonar y detectar cambios. | `Product` tiene campos `final`; carrito actualmente usa mapa mutable. |
| Layout constraints | Límites de ancho/alto que el padre comunica a sus hijos. | `LayoutBuilder` adapta columnas. |
| Overflow | Contenido supera el espacio que se le asignó. | Dropdown largo corregido con `isExpanded`/ellipsis. |
| Responsive | Interfaz que se adapta a tamaño/orientación del dispositivo. | Catálogo cambia columnas según ancho. |
| `const` | Constructor/objeto que puede ser constante y reutilizarse si sus datos son fijos. | `const Text('Ingresar')`. |
| `Navigator` | Administrador de la pila de pantallas. | `push`, `pop`, `pushReplacement`. |
| Ruta | Una pantalla/destino que se coloca en la pila del navegador. | `MaterialPageRoute`. |
| Repository | Capa que obtiene y transforma datos de una fuente externa para la UI. | No existe como capa formal todavía; mejora recomendada. |
| Provider/Riverpod/Bloc | Opciones de administración de estado compartido. | No están instalados ni se usan en el proyecto actual. |
| Semántica/accesibilidad | Información que tecnologías de asistencia necesitan para entender acciones/contenido. | `tooltip` en botones de icono. |
| Widget test | Prueba que crea árbol Flutter y verifica interacción/resultado visual. | Prueba de registro y formulario estrecho. |
| Mock/fake | Sustituto de dependencia real para probar sin servidor o almacenamiento real. | Próximo paso: sustituir Dio en pruebas de UI. |
| Backend | Servicio que valida reglas, autentica, persiste y calcula resultados. | FastAPI y SQLModel. |
| Fuente de verdad | Componente autoritativo para un dato. | FastAPI define precio final y total de venta/pedido. |
| Accesibilidad | Diseño que personas con distintas capacidades pueden utilizar. | Contraste, labels, tooltips, foco y escala de texto. |

## 20 preguntas de repaso

Intenta responder antes de leer la sección de soluciones.

1. ¿Qué diferencia hay entre un widget y el objeto de estado `State`?
2. ¿Qué función cumple `MaterialApp` en `main.dart`?
3. ¿Por qué el login está dentro de `SingleChildScrollView`?
4. ¿En qué se diferencia `TextField` de `TextFormField`?
5. ¿Qué devuelve un validador correcto de `TextFormField` cuando el valor es válido?
6. ¿Por qué se llama `setState` al comenzar una petición?
7. ¿Qué riesgo evita revisar `mounted` después de `await`?
8. ¿Por qué se llama `dispose` a `TextEditingController`?
9. ¿Qué gana catálogo usando `GridView.builder` frente a un `Column` con tarjetas?
10. ¿Qué adapta `LayoutBuilder` en la cuadrícula de productos?
11. ¿Qué hace el debounce y por qué se cancela en `dispose`?
12. ¿Cuál es el trabajo del `ApiClient` y qué añade su interceptor?
13. ¿Qué diferencia hay entre consultar `GET /catalogo/productos` y `GET /productos/buscar`?
14. ¿Qué transforma `Product.fromJson`?
15. ¿Por qué la UI no debe enviar como verdad el total definitivo de una venta?
16. ¿Qué diferencia hay entre `Navigator.push` y `pushReplacement`?
17. ¿Cómo vuelve el formulario de inventario y solicita recarga al padre?
18. ¿Qué es un error común al poner dropdowns con textos largos en móvil?
19. ¿Por qué el proyecto no necesita introducir Riverpod solo porque sea popular?
20. ¿Qué capas añadirías para que una pantalla no sepa la ruta HTTP ni procese mapas JSON?

## Respuestas

1. El widget declara configuración/interfaz; `State` guarda datos mutables y
   provoca reconstrucciones.
2. Configura tema Material, título, comportamiento global y pantalla inicial.
3. Para permitir scroll cuando el teclado o la pantalla reducida no dejan ver
   todos los campos.
4. `TextFormField` integra validación y `Form`; `TextField` es edición básica.
5. `null`; una cadena con mensaje indica que el valor no es válido.
6. Para que Flutter reconstruya la UI con el nuevo estado, por ejemplo
   mostrando progreso.
7. Evita operar sobre una pantalla/Estado ya eliminado, como `setState` tras
   cerrar una ruta.
8. Libera el recurso que escucha/gestiona edición de texto y evita retener
   memoria.
9. Construye elementos bajo demanda y escala mejor a listas grandes.
10. Usa las restricciones reales del padre para elegir cuántas columnas se
    muestran.
11. Agrupa pulsaciones rápidas en una búsqueda; se cancela para no ejecutar
    callback sobre una pantalla destruida.
12. Configura Dio, token seguro y mensajes de error; el interceptor adjunta
    credenciales a solicitudes autenticadas.
13. El catálogo público devuelve datos visibles a cliente; la búsqueda interna
    está protegida y agrega stock/ubicación.
14. Convierte campos JSON y tipos variables (por ejemplo decimal string/num)
    al modelo Dart `Product`.
15. Puede estar manipulado o desactualizado; FastAPI debe validar stock,
    aplicar precio vigente y calcular importes autoritativos.
16. `push` conserva la pantalla anterior en la pila; `pushReplacement` la
    reemplaza y no se vuelve a ella con “atrás”.
17. El formulario hace `Navigator.pop(context, true)` al guardar; el padre
    espera resultado y llama `_load`.
18. El texto excede ancho y genera overflow; usar `isExpanded`, límites y
    `TextOverflow.ellipsis` cuando corresponda.
19. Porque el proyecto usa estado local y no hay una necesidad actual que
    justifique dependencia y curva de aprendizaje extra.
20. Un repositorio/servicio tipado entre UI y Dio, más modelos DTO tipados para
    serializar respuestas.

## Checklist de progreso

Marca **Lo domino** solo si puedes explicar el porqué y recorrer el código,
además de reconocer el nombre.

| Competencia | Lo domino | Me falta |
|---|:---:|:---:|
| Explico `MaterialApp`, `Scaffold` y `AppBar` | ☐ | ☐ |
| Dibujo el árbol de una pantalla real | ☐ | ☐ |
| Elijo entre `Row`, `Column`, `Expanded`, `Wrap` y listas | ☐ | ☐ |
| Creo un formulario con validación entendiendo el `FormState` | ☐ | ☐ |
| Administro controladores y los libero en `dispose` | ☐ | ☐ |
| Distingo `StatelessWidget` de `StatefulWidget` | ☐ | ☐ |
| Sé cuándo y por qué llamar `setState` | ☐ | ☐ |
| Evito usar estado/contexto luego de desmontar una pantalla | ☐ | ☐ |
| Puedo explicar cada fase loading/error/success | ☐ | ☐ |
| Interpreto JSON con tipos seguros y manejo datos inválidos | ☐ | ☐ |
| Sigo una request desde el toque hasta FastAPI y su respuesta | ☐ | ☐ |
| Entiendo JWT e interceptor sin confundirlos con UI | ☐ | ☐ |
| Explico la pila de `Navigator` y el resultado de `pop` | ☐ | ☐ |
| Adapto un formulario a pantalla estrecha y texto largo | ☐ | ☐ |
| Puedo escribir y ejecutar una prueba de widget | ☐ | ☐ |
| Sé explicar qué no puede validar una prueba de widget | ☐ | ☐ |
| Identifico responsabilidades que conviene mover a repositorio | ☐ | ☐ |
| Distingo total preliminar de total autoritativo del servidor | ☐ | ☐ |
| Puedo proponer una prueba para error HTTP y lista vacía | ☐ | ☐ |
| Puedo justificar si necesito gestor de estado compartido | ☐ | ☐ |

## Siguiente reto profesional

Elige una pantalla de pedidos y dibuja su flujo de datos completo. Luego
propón, sin tocarla aún, tres interfaces tipadas para retirar de ella el acceso
directo a Dio, los mapas JSON y el estado de carga/error. Contrasta tu propuesta
con `04_analisis_calidad.md`.
