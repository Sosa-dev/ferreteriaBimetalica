# 04. Análisis de calidad: oportunidades de mejora

Este documento describe oportunidades observadas en el código actual; no
modifica ni corrige los archivos del proyecto. Una mejora no siempre significa
que el código falle: puede señalar un riesgo de crecimiento, pruebas o
mantenimiento.

## 1. Widgets y pantallas extensos

### Catálogo

`lib/screens/catalog_screen.dart` combina en un mismo `State` la consulta,
debounce, estado de carga/error, cuadrícula de cliente, resultados internos de
empleado, carrito local y navegación al carrito. La diferencia de modo es una
condición booleana (`employeeMode`) que altera título, filtros, ruta HTTP,
resultados y acciones.

**Cómo lo separaría profesionalmente:** extraería `CustomerCatalogView` y
`EmployeeProductSearchView` para sus presentaciones específicas, manteniendo
comunes los componentes de búsqueda/producto cuando compartan contrato. La
lógica HTTP pasaría a un repositorio. Esto reduce ramas y permite probar los
dos usos con independencia.

### Inventario

`lib/screens/inventory_screen.dart` reúne carga de tres recursos, CRUD,
confirmación de borrado, pestañas, lista, formulario y diálogo genérico.
`ProductFormScreen` contiene todos los campos, validación, conversión del
payload y envío.

**Mejora profesional:** separar `ProductForm`, `CatalogEntryForm` y
`InventoryRepository`; extraer filas de producto y estados de pantalla. El
formulario debería convertir y validar el modelo de entrada de forma explícita,
no construir el mapa HTTP en el widget.

### Pedidos

`lib/screens/order_screens.dart` agrupa carrito, historial, panel de
empleado, formateadores, mapa de transiciones y estados de error. Los dos
listados repiten `_loadOrders`, conversión de lista dinámica, control de error
y refresco.

**Mejora profesional:** separar las pantallas por archivo y crear un servicio
de pedidos que comparta consultas sin compartir presentación. Extraer
`Order`, `OrderLine` y `OrderStatus` tipados.

### POS y factura

`PosScreen` realiza búsqueda, control de existencias local, carrito, datos
fiscales, cobro, consulta de factura y navegación. `InvoiceScreen` también
construye un documento PDF. El límite de responsabilidades es amplio.

**Mejora profesional:** separar componentes de búsqueda, carrito, formulario de
facturación, cálculo de presentación y servicio PDF; conservar los importes
finales del servidor.

## 2. Acceso HTTP desde widgets

Varias pantallas llaman directamente a `ApiClient.instance.dio` y decodifican
JSON dentro de callbacks (`auth_screens.dart`, `catalog_screen.dart`,
`inventory_screen.dart`, `pos_screen.dart`, `order_screens.dart`,
`invoice_screen.dart`). El singleton da una configuración común, pero las
pantallas todavía conocen rutas, payloads y forma de respuesta de FastAPI.

**Riesgo:** un cambio de endpoint o JSON obliga a modificar UI; las pruebas de
widget necesitan aislar HTTP; mapas dinámicos permiten errores en ejecución que
el analizador no detecta.

**Enfoque profesional:** introducir repositorios (`ProductRepository`,
`OrderRepository`, etc.) con métodos tipados, como `searchProducts()` o
`createOrder()`. La UI expresaría estados; el repositorio encapsularía Dio y
la conversión JSON.

## 3. Tipos dinámicos en respuestas

Pedidos, ventas y factura se manejan con `Map<String, dynamic>` y listas
`dynamic`. `Product` sí es un modelo explícito con `fromJson`, pero la misma
protección no existe para `Order`, `OrderDetail`, `Sale` e `Invoice`.

**Riesgo:** un nombre incorrecto de clave o un `as num` sobre un texto puede
fallar solo al llegar a una pantalla concreta.

**Enfoque profesional:** modelos de dominio con factories/serialización
probadas y estados tipados. Representar el estado de pedido como enum local
con conversión explícita al valor que espera la API.

## 4. Estado manual y cantidad de `setState`

La app usa `StatefulWidget` y `setState`; no es incorrecto para esta escala.
Sin embargo, cada pantalla mantiene combinaciones de booleanos (`_loading`,
`_error`, `_searching`, `_charging`) y datos. El estado podría entrar en
combinaciones ambiguas —por ejemplo, error y lista previa a la vez—.

En carrito, `OrderCartScreen` recibe un mapa mutable y lo modifica
directamente; comunica cambios mediante callbacks. Esto hace que el hijo
escriba en el estado que conceptualmente pertenece al padre.

**Enfoque profesional:** primero modelar estados explícitos (cargando,
completado, error); levantar el carrito a un propietario único; después
considerar Riverpod/Bloc si se comparte entre varias rutas o sobrevive a la
pantalla. No se añade un gestor de estado solo por moda.

## 5. Peticiones duplicadas y respuestas fuera de orden

El debounce del catálogo evita muchas llamadas mientras se escribe, pero una
consulta anterior todavía podría responder después de una búsqueda nueva. En
tal caso, el resultado antiguo puede sobrescribir el nuevo. El POS consulta en
cada cambio del `TextField`, sin debounce.

**Enfoque profesional:** cancelar la petición anterior con `CancelToken` de
Dio, usar un número de secuencia para ignorar respuestas antiguas y aplicar
debounce también al POS.

## 6. Controladores y ciclo de vida

Los formularios principales liberan sus controladores en `dispose`, lo cual es
positivo. Conviene conservar este patrón en todo campo nuevo. Después de
`await`, las pantallas comprueban `mounted` antes de usar `context` o actualizar
estado en la mayoría de los flujos.

**Riesgo al ampliar:** añadir una llamada asíncrona y usar `setState`,
`Navigator` o `ScaffoldMessenger` después de que la persona cierre la pantalla
puede causar “setState called after dispose”.

**Práctica:** después de cada `await`, verifica si el código vuelve a tocar
`State` o `BuildContext`; si lo hace, conserva el guard `if (!mounted) return`.

## 7. Validación y precisión de importes

En `ProductFormScreen`, el validador comprueba valores numéricos, pero el
payload se construye después mediante `double.parse`/`int.parse`. El precio de
compra vacío se convierte a `0`, y en un producto existente el campo aparece
inicialmente vacío si no se rellena. Son decisiones de negocio implícitas.

En POS, la interfaz calcula IVA y total con `double`; sirve como vista previa,
pero dinero requiere precisión decimal y el servidor debe ser autoritativo.

**Enfoque profesional:** una función de conversión validada antes de iniciar
loading; reglas explícitas para campos opcionales; decimal/centavos o
aritmética decimal en la fuente autoritativa; errores de validación por campo.

## 8. Experiencia en fallos de red

`ApiClient.errorMessage` centraliza mensajes, y las pantallas distinguen
loading/error. En inventario, `Future.wait` agrupa productos, categorías y
ubicaciones: si falla una sola petición, la carga conjunta falla aunque las
otras dos hayan terminado.

**Enfoque profesional:** decidir si la pantalla necesita las tres fuentes para
mostrar algo. Si los recursos pueden operar independientemente, cargar cada
sección por separado; si son requisito conjunto, mantener el fallo explícito y
añadir una explicación contextual.

Al abrir el detalle de pedido, el fallo se comunica con `SnackBar`; convendría
mostrar una acción local de reintento dentro de la fila expandida para que la
persona no tenga que colapsar/expandir sin saber qué ocurrió.

## 9. Accesibilidad y responsive

El catálogo usa `LayoutBuilder`, la pantalla de acceso limita su anchura y el
formulario de producto expande dropdowns y elide textos largos. Son buenas
decisiones y la prueba de widget de 320 px cubre un caso real.

**Oportunidades:** fijar alturas de tarjetas puede cortar contenido con escala
de fuente grande; algunos `IconButton` internos podrían ganar `tooltip`; debe
comprobarse contraste y semántica del logo; mensajes no deben depender solo de
color.

**Enfoque profesional:** probar escalas de texto, orientación, tamaño mínimo
de toque, lector de pantalla y teclado; preferir restricciones adaptativas a
alturas arbitrarias cuando el contenido varíe.

## 10. Pruebas: buen punto de partida y próximos pasos

Hay pruebas de parseo de `Product`, navegación de registro, factura y prueba
responsive del formulario de producto. Eso protege comportamientos concretos.

**Falta cubrir:** respuestas Dio de éxito/error, debounce y carrera de
búsqueda, validadores, límites del carrito, transición de pedido desde UI y
accesibilidad. No hay pruebas unitarias de widgets de pedidos ni pruebas de
integración Flutter–FastAPI.

**Enfoque profesional:** introducir cliente HTTP reemplazable; probar
repositorios con adaptador mock; pruebas de widget para escenarios loading,
error, vacío y éxito; pruebas de integración para el contrato API.

## 11. Dependencia de contrato con FastAPI

La interfaz conoce paths concretos, nombres JSON y estados de pedido. La
separación por roles también aparece en los controles de FastAPI; ocultar un
botón en Flutter nunca sustituye la autorización del backend.

**Enfoque profesional:** documentar contratos, mantener permisos en servidor,
tratar mensajes HTTP de validación y evitar confiar en importes o stock
calculados por el móvil. Considerar OpenAPI como fuente para generar cliente
tipado si el equipo y el contrato se estabilizan.

## 12. Constantes y repetición

Hay buen uso de `const` para textos, iconos y estructuras inmutables. Algunas
tarjetas repiten estilos/márgenes y las pantallas repiten formateadores de
importe/fecha.

**Enfoque profesional:** centralizar formatos y componentes cuando la
repetición sea semánticamente igual; mantener estilos inline cuando sean
únicos. Abstraer demasiado pronto también dificulta entender el árbol.

## Prioridad recomendada de mejora

1. Modelos tipados para respuestas de pedido y factura.
2. Repositorios pequeños para quitar Dio de los widgets.
3. Estados explícitos loading/error/success y dueño único del carrito.
4. Pruebas de estado/error y control de carreras de búsqueda.
5. Dividir pantallas largas y repetir validación responsive/accesible.

## Qué evitar al “profesionalizar”

- No introducir Provider/Riverpod/Bloc sin explicar qué estado compartido
  resolverá.
- No reemplazar cada `Column` por un componente solo para reducir líneas.
- No mover reglas de permisos o importes críticos exclusivamente al cliente.
- No transformar errores HTTP en mensajes de éxito o valores por defecto
  silenciosos.
