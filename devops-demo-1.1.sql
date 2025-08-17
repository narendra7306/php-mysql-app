USE devopsdb;

CREATE TABLE IF NOT EXISTS dbversion (
  version VARCHAR(10) NOT NULL,
  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO dbversion (version) VALUES ('1.1');

