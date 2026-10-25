-- Camada de incerteza (docs/08): versão do ficheiro de parâmetros usado em cada avaliação, para que
-- a decisão possa ser reconstruída (auditoria). Os graus de crença, com as contribuições, ficam no
-- JSON da decisão. Nulo nas avaliações anteriores à camada de incerteza.
alter table avaliacao add column versao_parametros_incerteza varchar(100);
