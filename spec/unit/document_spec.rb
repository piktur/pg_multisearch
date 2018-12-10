# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PgMultisearch::Document do
  let(:model_name) do
    instance_double(
      'ActiveModel::Name',
      to_s: 'Model'
    )
  end

  let(:model) do
    class_double(
      'ActiveRecord::Base',
      model_name: model_name,
      _to_partial_path: 'models/model'
    )
  end

  before do
    stub_const 'Model', model
    stub_const 'Document', Struct.new(:attributes, :rank) {
      include PgMultisearch::Document::Base
      alias_method :name, :attribute
    }

    Document.model = Model
  end

  let(:data) { { __id__: 1, type: 'Model', name: 'foo' } }
  let(:json) { Oj.dump(data) }

  describe '.call' do
    subject { Model::Document }

    context 'without block' do
      before do
        described_class.call(Model)
      end

      it 'assigns a Struct definition to :Document within model namespace' do
        expect(subject).to be < described_class::Base
        expect(subject.model).to eq(Model)
      end
    end

    context 'with block' do
      before do
        described_class.call(Model) do |dfn|
          def extended?; true; end
        end
      end

      let(:instance) { Model::Document.new }

      it 'applies the block to the Struct definition' do
        expect(instance).to be_extended
      end
    end
  end

  context 'with JSON input' do
    subject { Document.new(json) }

    describe '#attributes' do
      it 'should assign input to :attributes' do
        expect(subject.attributes).to eq(data)
      end
    end
  end

  context 'with Hash input' do
    describe '#attributes' do
      subject { Document.new(data) }

      it 'should assign input to :attributes' do
        expect(subject.attributes).to eq(data)
      end
    end
  end

  describe '#rank' do

  end
end
