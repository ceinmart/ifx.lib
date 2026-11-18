-- Project: ifxlib
-- File: sql/unregister.sql
-- Version: 1.4.9
-- Created: 2026-11-18 09:23:03 -0300
-- Created by: ChatGPT - OpenAI
-- Run in the same database where the UDRs were registered.

DROP PROCEDURE IF EXISTS sp_yield(INTEGER);
DROP PROCEDURE IF EXISTS sp_yield();
DROP PROCEDURE IF EXISTS sp_cpu_apply_policy(INTEGER, INTEGER);
DROP PROCEDURE IF EXISTS sp_cpu(INTEGER);
DROP PROCEDURE IF EXISTS sp_cpu();
DROP FUNCTION IF EXISTS sp_current2();
