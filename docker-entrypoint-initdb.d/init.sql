CREATE TABLE todo (
  id SERIAL NOT NULL PRIMARY KEY,
  content VARCHAR(255)
);

INSERT INTO todo (content)
VALUES
    ('Homework'),
    ('Hairdresser apointment'),
    ('Yoga class')
;
