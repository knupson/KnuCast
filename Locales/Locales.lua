local _, ns = ...
local KL = LibStub('KnuLib-1.0')

ns.L = KL:NewLocale({
    ['Highlights situational spells on action buttons and crosses out the ones that do not work'] = 'Resalta hechizos situacionales en botones de acción y marca con una cruz roja los que no sirven',
    ['Status: glow=%s, cross=%s, sound=%s, test=%s'] = 'Estado: brillo=%s, cruz=%s, sonido=%s, prueba=%s',
    ['on'] = 'activado',
    ['off'] = 'desactivado',
    ['Glow overlay: %s'] = 'Capa de brillo: %s',
    ['Red cross: %s'] = 'Cruz roja: %s',
    ['Sound alert: %s'] = 'Alerta de sonido: %s',
    ['Test mode: %s'] = 'Modo de prueba: %s',
    ['Commands: /knu cast [glow on|off | grey on|off | sound on|off | debug | test]'] = 'Comandos: /knu cast [glow on|off | grey on|off | sound on|off | debug | test]',
    ['Debug: targetType=%s, casting=%s, buttons=%d, withRules=%d'] = 'Depuración: tipo de objetivo=%s, lanzando=%s, botones=%d, con regla=%d',
    ['Rule %d: %s (%s) - %d buttons - applies: %s - mark: %s'] = 'Regla %d: %s (%s) - %d botones - cumple: %s - marca: %s',
    ['unknown'] = 'no se sabe',
    ['glowing'] = 'brillo',
    ['greyed'] = 'cruz',
    ['unmarked'] = 'ninguna',
    ['pending'] = 'pendiente',
    ['missing in this client'] = 'no existe en este cliente',
    ['secret'] = 'secreto',
    ['none'] = 'ninguno',
    ['yes'] = 'sí',
    ['no'] = 'no',
    ['Like it? Add it to your favorites on CurseForge and leave a comment: %s'] = '¿Te sirve? Marcalo como favorito en CurseForge y dejá un comentario: %s',
    ['Other KNU addons: KnuCompanion (%s) and more at %s'] = 'Otros addons de KNU: KnuCompanion (%s) y más en %s',
    ['Found a bug? Report it with the BugSack error text: %s'] = '¿Encontraste un error? Reportalo con el texto que copia BugSack: %s',
})
