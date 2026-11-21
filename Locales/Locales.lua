local _, ns = ...
local KL = LibStub('KnuLib-1.0')

ns.L = KL:NewLocale({
    ['Situational spell highlights on action buttons'] = 'Resaltado de hechizos situacionales en botones de acción',
    ['Status: glow=%s, grey=%s, sound=%s, test=%s'] = 'Estado: brillo=%s, gris=%s, sonido=%s, prueba=%s',
    ['on'] = 'activado',
    ['off'] = 'desactivado',
    ['Glow overlay: %s'] = 'Capa de brillo: %s',
    ['Grey overlay: %s'] = 'Capa gris: %s',
    ['Sound alert: %s'] = 'Alerta de sonido: %s',
    ['Test mode: %s'] = 'Modo de prueba: %s',
    ['Commands: /knu cast [glow on|off | grey on|off | sound on|off | debug | test]'] = 'Comandos: /knu cast [glow on|off | grey on|off | sound on|off | debug | test]',
    ['Debug: targetType=%s, casting=%s, buttons=%d, withRules=%d'] = 'Depuración: tipoObjetivo=%s, lanzando=%s, botones=%d, conRegla=%d',
    ['Rule %d: %s (%s) - %d buttons - applies: %s - mark: %s'] = 'Regla %d: %s (%s) — %d botones — cumple: %s — marca: %s',
    ['unknown'] = 'no se sabe',
    ['glowing'] = 'brillo',
    ['greyed'] = 'gris',
    ['unmarked'] = 'ninguna',
    ['pending'] = 'pendiente',
    ['missing in this client'] = 'no existe en este cliente',
    ['secret'] = 'secreto',
    ['none'] = 'ninguno',
    ['yes'] = 'sí',
    ['no'] = 'no',
})
