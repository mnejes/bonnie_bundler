module CqlElm
  class Parser
    #Fields are combined with the refId to find elm node that corrosponds to the current annotation node.
    @fields = ['expression', 'operand', 'suchThat']
    @html_hash = {"&amp;": '&', "&quot;": '"', "&lt;": '<', "&gt;": '>', "&apos;": "'"}
    @previousNoTrailingSpaceNotPeriod = false
    
    def self.parse(elm_xml)
      ret = {
        statements: [],
        identifier: {}
      }
      @doc = Nokogiri::XML(elm_xml) {|d| d.noblanks}
      #extract library identifier data
      ret[:identifier][:id] = @doc.css("identifier").attr("id").value()
      ret[:identifier][:version] = @doc.css("identifier").attr("version").value()
      
      #extracts the fields of type "annotation" and their children.
      annotations = @doc.css("annotation")
      annotations.each do |node|
          node, define_name = parse_node(node)
          if !define_name.nil?
            node[:define_name] = define_name
            ret[:statements] << node
          end
      end
      ret
    end
    
    #Recursive function that traverses the annotation tree and constructs a representation
    #that will be compatible with the front end.
    def self.parse_node(node)
      ret = {
        children: []
      }
      define_name = nil
      node.children.each do |child|
        #Nodes with the 'a' prefix are not leaf nodes
        if child.namespace.respond_to?(:prefix) && child.namespace.prefix == 'a'
          node_type = extract_node_type(child)
          #Parses the current child recursively. child_define_name will bubble up to indicate which
          #statement is currently being traversed.
          node, child_define_name = parse_node(child)
          node[:node_type] = node_type  unless node_type.nil?
          node[:ref_id] = child['r'] unless child['r'].nil?
          define_name = child_define_name unless child_define_name.nil? 
          ret[:children] << node
        else
          if (/^define/ =~ child.to_html)
            define_name = child.to_html.split("\"")[1]
            # Modify special characters back in the the define_name
            @html_hash.each { |k,v| define_name.gsub!(k.to_s, v) }
          end
          clause_text = child.to_html.gsub(/\t/, "  ")
          # Modify special characters back in the clause text
          @html_hash.each { |k,v| clause_text.gsub!(k.to_s, v) }
          clause = {
            text: clause_text
          }
          clause[:ref_id] = child['r'] unless child['r'].nil?
          ret[:children] << clause
        end
      end
      return ret, define_name
    end
    
    def self.extract_node_type(child)
      ref_node = nil
      node_type = nil
      #Tries to pair the current annotation node with an elm node.
      @fields.each do |field|
        ref_node ||= @doc.at_css(field + '[localId="'+child['r']+'"]') unless child['r'].nil?
      end
      #Tries to extract the current node's type.
      node_type = ref_node['xsi:type'] unless ref_node.nil?
      node_type
    end

  end
end
