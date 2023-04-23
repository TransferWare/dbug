alter type std_object add attribute db_session varchar2(128 char) cascade;
alter type std_object add attribute db_username varchar2(128 char) cascade;
alter type std_object add attribute app_session varchar2(128 char) cascade;
alter type std_object add attribute app_username varchar2(128 char) cascade;
alter type std_object add member procedure set_session_attributes(self in out nocopy std_object) cascade;
alter type std_object add final member function get_session_attributes(self in std_object) return varchar2 cascade;
alter type std_object add final member function belongs_to_same_session(p_std_object in std_object) return integer cascade;
