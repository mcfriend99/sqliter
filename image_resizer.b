import imagine {*}
import os

var final_width = 48
var root_dir = os.join_paths(os.dir_name(__root__), 'src/assets/images/')
var processed_dir = os.join_paths(root_dir, 'processed')

var images = os.read_dir(root_dir).filter(@(x) {
  return !x.starts_with('.')
}).map(@(x) {
  return os.join_paths(root_dir, x)
})

if !os.dir_exists(processed_dir) {
  os.create_dir(processed_dir)
}

for image in images {
  if os.dir_exists(image) continue

  Image.from_png(image).use(@(img) {
    echo 'Processing ${image}...'

    var meta = img.meta()
    var final_height = (final_width / meta.width * meta.height) // 1

    Image.new(meta.width, meta.height, true).use(@(newIm) {
      newIm.save_alpha(true)

      # set transparent background
      var transparent = newIm.allocate_color(0, 0, 0, 127)
      newIm.fill(0, 0, transparent)

      iter var x = 0; x < meta.width; x++ {
        iter var y = 0; y < meta.height; y++ {
          var pixel = img.get_pixel(x, y)
          var color = decompose(pixel)

          if (color.r < 240 and color.g < 240 and color.b < 240 and color.a == 0) or color.a > 0 {
            newIm.set_pixel(x, y, pixel)
          }
        }
      }

      Image.new(final_width, final_height, true).use(@(img) {
        img.alpha_blending(false)
        img.save_alpha(true)

        img.copy_resampled(newIm, 0, 0, 0, 0, final_width, final_height, meta.width, meta.height)
        
        var destination = os.join_paths(processed_dir, os.base_name(image))
        img.export_png(destination)

        echo 'Saved to ${destination}.'
      })
    })
  })
}
