# Estrategias de Despliegue: Blue/Green, Canary

Blue/Green y Canary son formas de publicar nuevas versiones sin tumbar producción.

## Blue/Green

Tienes 2 entornos iguales:

- `Blue` = versión actual (usuarios reales).
- `Green` = nueva versión.

Flujo típico:

1. Despliegas la nueva versión en `Green`.
2. Ejecutas pruebas funcionales y de humo.
3. Cambias todo el tráfico de golpe hacia `Green`.
4. Si falla, vuelves rápidamente a `Blue`.

Ventajas:

- Rollback muy rápido.
- Menor riesgo de downtime.

Costo/Complejidad:

- Debes mantener 2 entornos completos (infra, configuración y datos compatibles).

## Canary

Publicas la nueva versión solo para un porcentaje pequeño de usuarios o tráfico (por ejemplo, `5%`).

Flujo típico:

1. Publicas versión nueva para un porcentaje bajo (`5%`).
2. Observas métricas: errores, latencia, consumo de recursos, experiencia de usuario.
3. Si todo va bien, incrementas progresivamente (`5% -> 25% -> 50% -> 100%`).
4. Si falla, regresas a `0%` y se mantiene la versión estable.

Ventajas:

- Riesgo muy controlado.
- Detectas problemas antes de afectar a todos los usuarios.

Costo/Complejidad:

- Necesitas enrutamiento por porcentajes y monitoreo sólido.

## ¿Cuándo usar cada una?

- Usa `Blue/Green` cuando necesitas cambios rápidos de versión y rollback inmediato.
- Usa `Canary` cuando el riesgo funcional es alto y quieres validar con tráfico real antes de exponer a todos.

En muchos equipos se combinan:

1. Despliegue a un entorno `Green`.
2. Canary dentro de `Green`.
3. Corte final de tráfico cuando la versión está validada.

## Buenas prácticas para el curso

- Define métricas de éxito antes de desplegar: tasa de error, p95/p99 de latencia, throughput.
- Automatiza alarmas y condiciones de rollback.
- Usa health checks y smoke tests en cada etapa.
- Evita cambios de base de datos no retrocompatibles durante la primera fase del despliegue.
- Documenta un plan de rollback operativo (quién decide, umbrales, tiempo máximo de respuesta).

## Resumen

- `Blue/Green`: cambio total de tráfico entre dos entornos idénticos, rollback inmediato.
- `Canary`: exposición gradual por porcentaje, validación progresiva con menor impacto potencial.
