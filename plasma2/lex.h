extern char *statement, *scanpos, *tokenstr;
extern t_token scantoken, prevtoken;
extern int tokenlen;
extern long constval;
extern char inputline[];
void parse_error(char *errormsg);
int next_line(void);
void scan_rewind(char *backptr);
t_token scan(void);