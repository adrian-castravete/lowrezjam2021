function love.conf(t)
  t.identity = 'fkbm-lowrezjam2021'
  t.version = '11.1'
  t.accelerometerjoystick = false
  t.externalstorage = true
  t.gammacorrect = true

  local w = t.window
  w.title = "LowRezJam 2021 Entry"
  w.icon = nil
  w.width = 960
  w.height = 720
  w.minwidth = 320
  w.minheight = 240
  w.resizable = true
  w.fullscreentype = 'desktop'
  w.fullscreen = false
  w.usedpiscale = false
  w.hidpi = true
end
