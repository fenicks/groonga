class TestRegexp < ExpressionRewriterTestCase
  def setup
    Groonga::Schema.define do |schema|
      schema.create_table("expression_rewriters",
                          :type => :hash,
                          :key_type => :short_text) do |table|
        table.text("plugin_name")
      end

      schema.create_table("Logs") do |table|
        table.text("message")
      end

      schema.create_table("Terms",
                          :type => :patricia_trie,
                          :default_tokenizer => "TokenRegexp",
                          :normalizer => "NormalizerAuto") do |table|
        table.index("Logs", "message")
      end
    end

    @rewriters = Groonga["expression_rewriters"]
    @rewriters.add("optimizer",
                   :plugin_name => "expression_rewriters/optimizer")

    @logs = Groonga["Logs"]
    setup_logs
    setup_expression(@logs)
  end

  def setup_logs
    10.times do |i|
      @logs.add(:message => "Groonga#{i}")
    end
    2.times do |i|
      @logs.add(:message => "Rroonga#{i}")
    end
    100.times do |i|
      @logs.add(:message => "Mroonga#{i}")
    end
  end

  def teardown
    teardown_expression
  end

  def test_and
    filter = "(message @~ 'Groonga') && (message @~ 'Rroonga')"
    assert_equal(<<-DUMP, dump_rewritten_plan(filter))
[0]
  op:         <regexp>
  logical_op: <or>
  index:      <[#<column:index Terms.Logs_message range:Logs sources:[Logs.message] flags:POSITION>]>
  query:      <"Rroonga">
  expr:       <0..2>
[1]
  op:         <regexp>
  logical_op: <and>
  index:      <[#<column:index Terms.Logs_message range:Logs sources:[Logs.message] flags:POSITION>]>
  query:      <"Groonga">
  expr:       <3..5>
    DUMP
  end
end