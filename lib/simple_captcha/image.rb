require 'tempfile'
module SimpleCaptcha #:nodoc
  module ImageHelpers #:nodoc

    mattr_accessor :image_styles
    @@image_styles = {
      'embosed_silver'  => ['-fill darkblue', '-shade 20x60', '-background white'],
      'simply_red'      => ['-fill darkred', '-background white'],
      'simply_green'    => ['-fill darkgreen', '-background white'],
      'simply_blue'     => ['-fill darkblue', '-background white'],
      'distorted_black' => ['-fill darkblue', '-edge 10', '-background white'],
      'all_black'       => ['-fill darkblue', '-edge 2', '-background white'],
      'charcoal_grey'   => ['-fill darkblue', '-charcoal 5', '-background white'],
      'almost_invisible' => ['-fill red', '-solarize 50', '-background white']
    }

    DISTORTIONS = ['low', 'medium', 'high']

    IMPLODES = { 'none' => 0, 'low' => 0.1, 'medium' => 0.2, 'high' => 0.3 }
    DEFAULT_IMPLODE = 'medium'

    class << self

      def image_params(key = 'simply_blue')
        image_keys = @@image_styles.keys

        style = begin
          if key == 'random'
            image_keys[rand(image_keys.length)]
          else
            image_keys.include?(key) ? key : 'simply_blue'
          end
        end

        @@image_styles[style]
      end

      def distortion(key='low')
        key =
          key == 'random' ?
          DISTORTIONS[rand(DISTORTIONS.length)] :
          DISTORTIONS.include?(key) ? key : 'low'
        case key.to_s
          when 'low' then return [0 + rand(2), 80 + rand(20)]
          when 'medium' then return [2 + rand(2), 50 + rand(20)]
          when 'high' then return [4 + rand(2), 30 + rand(20)]
        end
      end

      def implode
        IMPLODES[SimpleCaptcha.implode] || IMPLODES[DEFAULT_IMPLODE]
      end
    end

    if RUBY_VERSION < '1.9'
      class Tempfile < ::Tempfile
        # Replaces Tempfile's +make_tmpname+ with one that honors file extensions.
        def make_tmpname(basename, n = 0)
          extension = File.extname(basename)
          sprintf("%s,%d,%d%s", File.basename(basename, extension), $$, n, extension)
        end
      end
    end

    private

      def generate_simple_captcha_image(simple_captcha_key) #:nodoc

        amplitude, frequency = ImageHelpers.distortion(SimpleCaptcha.distortion)
        text = Utils::simple_captcha_value(simple_captcha_key)

        params = ImageHelpers.image_params(SimpleCaptcha.image_style).dup
        params << "-size #{SimpleCaptcha.image_size}"
        params << "-wave #{amplitude}x#{frequency}"
        params << "-gravity Center"
        params << "-pointsize 22"
        params << "-implode #{ImageHelpers.implode}"
        unless SimpleCaptcha.font.empty?
          params << "-font #{SimpleCaptcha.font}"
        end
        params << "label:#{text}"
        if SimpleCaptcha.noise and SimpleCaptcha.noise > 0
          params << "-evaluate Uniform-noise #{SimpleCaptcha.noise}"
        end
        params << "captcha.jpeg"
        SimpleCaptcha::Utils::run("convert", params.join(' '))
        "captcha.jpeg"
      end
  end
end
