# Ferretería Bimetálica

Aplicación Flutter móvil para los flujos de los Sprints 1 a 4, conectada a la
API FastAPI recuperada.

## Configurar la API

Por defecto, la aplicación usa `http://10.0.2.2:8000`, dirección de la máquina
anfitriona vista desde un emulador Android. Si ejecutas la app en un teléfono
físico, configura la dirección LAN de la computadora que ejecuta FastAPI:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

Reemplaza la IP de ejemplo por la IP de tu computadora. El servidor y el
teléfono deben estar en la misma red. Para un despliegue, usa una URL HTTPS.

## Pantallas disponibles

- Inicio de sesión y registro público de clientes.
- Inicio según el rol (propietario, empleado o cliente).
- Inventario: consulta y edición de productos, categorías y ubicaciones.
- Catálogo público para clientes y búsqueda de existencias/ubicación para
  empleados.
- Punto de venta: carrito, cálculo de IVA y captura de datos de facturación.
- Consulta e impresión de la factura que genere la API.

El backend debe estar iniciado y accesible desde el dispositivo. La impresión
fiscal necesita además que la API tenga configurados sus datos del emisor.
