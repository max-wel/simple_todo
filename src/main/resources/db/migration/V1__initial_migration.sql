create table todo
(
    id         bigint auto_increment
        primary key,
    task       varchar(1000)                      not null,
    created_at datetime default (utc_timestamp()) not null
);

