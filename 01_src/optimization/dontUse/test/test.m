d_model = 512;
N = 6;
h = 8;
dropout = 0.1;
vocab_size = 10000;
d_ff = 2048;

src_embed = Embeddings(d_model, vocab_size);
tgt_embed = Embeddings(d_model, vocab_size);
pos_enc = PositionalEncoding(d_model, dropout, 5000);
generator = Generator(d_model, vocab_size);

self_attn = MultiHeadedAttention(h, d_model, dropout);
src_attn = MultiHeadedAttention(h, d_model, dropout);
feed_forward = PositionwiseFeedForward(d_model, d_ff, dropout);

encoder_layer = EncoderLayer(d_model, self_attn, feed_forward, dropout);
decoder_layer = DecoderLayer(d_model, self_attn, src_attn, feed_forward, dropout);

encoder = Encoder(encoder_layer, N);
decoder = Decoder(decoder_layer, N);

model = EncoderDecoder(encoder, decoder, src_embed, tgt_embed, generator);
