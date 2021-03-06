class MessageParser
  def self.parse(tweet)

    tweet.text.downcase!
        
    return false unless tweet.text =~ /\^/
    
    venture_tags       = tweet.text.scan(/(\^[a-z0-9]+)/).uniq
        
    ventures = venture_tags.collect do |vt|
      Venture.find_or_create_by_tag(vt.to_s)
    end
    
    if ventures.any?
      need_tags  = tweet.text.scan(/![a-z0-9]+/).uniq
      
      needs = need_tags.collect do |nt|
        Need.find_or_create_by_tag(nt)
      end
      
      needs.each {|n| ventures.each {|v| n.ventures << v unless n.ventures.include? v}}
      
      account = Account.find_by_twitter_id(tweet.user.id)
      account = Account.create!(:twitter_id=>tweet.user.id,:name=>tweet.user.name,:screen_name=>tweet.user.screen_name,:url=>tweet.user.url,:description=>tweet.user.description,:profile_image_url=> tweet.user.profile_image_url,:account_type => AccountType.find_by_name('User')) unless account      
            
      message = Message.new(:twitter_id=>tweet.id, :twitter_text=>tweet.text,:account_id=>account.id)
      message.ventures << ventures
      message.needs << needs     
      
      begin
        message.save
      rescue Exception => e
        
      end      
    end
  end
  
  def self.get_messages_and_parse(options = Hash.new)
    message_last_updated_at = Message.maximum(:updated_at)
    # options[:since] = Message.maximum(:updated_at) unless options[:since] && message_last_updated_at.nil?
    
    Twitter::Base.new(TWITTER_USERNAME,TWITTER_PASSWORD).timeline(:friends,options).each do |tweet|
      MessageParser.parse(tweet)      
    end
  end
end