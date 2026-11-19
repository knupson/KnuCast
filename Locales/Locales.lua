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
    ['secret'] = 'secreto',
    ['none'] = 'ninguno',
    ['yes'] = 'sí',
    ['no'] = 'no',
})
