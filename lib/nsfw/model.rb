require "onnxruntime"

module NSFW
  class Model
    MODEL_PATH       = "vendor/onnx_models/nsfw.onnx"
    CATEGORIES       = ['drawings', 'hentai', 'neutral', 'porn', 'sexy']
    SAFETY_THRESHOLD = 0.85

    attr_reader :model

    def initialize(lazy: false)
      load_model! unless lazy
    end

    def predict(tensor)
      prediction = make_prediction(tensor)
      format_prediction(prediction)
    end

    def safe?(image)
      prediction = predict(image.tensor)
      prediction["neutral"] >= SAFETY_THRESHOLD
    end

    def loaded?
      !@model.nil?
    end

    def reshape_tensor(tensor)
      session = @model.instance_variable_get(:@session)
      session = session.instance_variable_get(:@session)
      ort_value = OnnxRuntime::OrtValue.new(session)
      ort_value.send(:reshape, tensor, [1, 224, 224, 3])
    end

    private

    def load_model!
      @model ||= OnnxRuntime::Model.new(MODEL_PATH)
    end

    def make_prediction(tensor)
      load_model! unless loaded?
      @model.predict({ "input" => reshape_tensor(tensor) })
    end

    def format_prediction(prediction)
      results = prediction.fetch("Identity").first
      CATEGORIES.zip(results).sort{|a,b| b.last - a.last }.to_h
    end
  end
end