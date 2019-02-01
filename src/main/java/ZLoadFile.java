import com.ibm.db2.jcc.*;
import java.io.*;
import java.sql.*;
import java.time.*;

public class ZLoadFile {

    static final String urlPrefix = "jdbc:db2:";

    String inputFileName;
    String blockModeFileName;
    String columnDefFileName;
    String url;
    String user;
    String password;
    String table;

    public static void main(String[] args) {
        if (args.length != 6) {
            System.err.println("This program requires these arguments:");
            System.err.println("  inputFileName columnDefFileName database-url user password tablename");
            System.err.println("");
            System.err.println("inputFileName:     csv file to load into z/OS database");
            System.err.println("columnDefFileName: csv file column definitions in format expected by z/OS load utility");
            System.err.println("database-url:      database URL in the form //host:port/location");
            System.err.println("user:              userid used to connect to database");
            System.err.println("password:          password used to connect to database");
            System.err.println("tablename:         table name to load, in schema.table format");
            System.exit(1);
        }
        String _inputFileName = args[0];
        String _columnDefFileName = args[1];
        String _url = urlPrefix + args[2];
        String _user = args[3];
        String _password = args[4];
        String _table = args[5];
        int rc = new ZLoadFile(_inputFileName, _columnDefFileName, _url, _user, _password, _table).run();
        System.exit(rc);
    }

    public ZLoadFile(String inputFileName, String columnDefFileName, String url, String user, String password, String table) {
        this.inputFileName = inputFileName;
        this.blockModeFileName = inputFileName + ".del";
        this.columnDefFileName = columnDefFileName;
        this.url = url;
        this.user = user;
        this.password = password;
        this.table = table;
    }

    public int run() {
        int returnCode;
        Connection con;
        try {
            String columnDefs = getColumnDefinitions();

            convertFileToBlockMode();

            // Load the driver
            log("Loading the JDBC driver");
            Class.forName("com.ibm.db2.jcc.DB2Driver");

            // Create the connection using the IBM Data Server Driver for JDBC and SQLJ
            log("Creating a JDBC connection to " + url + " with user " + user);
            con = DriverManager.getConnection (url, user, password);

            DB2Connection db2conn = (DB2Connection)con;
            String loadstmt = "TEMPLATE SORTIN DSN " + user + ".SORTIN.T&TIME. " +
                              "UNIT SYSDA SPACE(10,10) CYL DISP(NEW,DELETE,DELETE) " +
                              "TEMPLATE SORTOUT DSN " + user + ".SORTOUT.T&TIME. UNIT SYSDA " +
                              "SPACE(10,10) CYL DISP(NEW,DELETE,DELETE) " +
                              "TEMPLATE MAP DSN " + user + ".SYSMAP UNIT SYSDA " +
                              "SPACE(10,10) CYL DISP(NEW,DELETE,CATLG) " +
                              "LOAD DATA INDDN SYSCLIEN WORKDDN(SORTIN,SORTOUT) RESUME YES " +
                              "FORMAT DELIMITED ASCII CCSID(1252) MAPDDN MAP " +
                              "INTO TABLE " + table + " IGNOREFIELDS YES " + columnDefs;

            log("Uploading data");

            LoadResult lr = db2conn.zLoad(loadstmt, blockModeFileName, null);
            returnCode = lr.getReturnCode();
            String loadMessage = lr.getMessage();

            // Close the connection
            con.close();

            if (returnCode >= 8) {
                log("Upload of " + inputFileName + " FAILED.  Return code " + returnCode + ". " + loadMessage);
            } else {
                log("Upload of " + inputFileName + " complete.  Return code " + returnCode + ". " + loadMessage);
            }

        }

        catch (ClassNotFoundException e) {
            System.err.println("Could not load JDBC driver");
            System.out.println("Exception: " + e);
            e.printStackTrace();
            returnCode = 8;
        }

        catch(SQLException sqlex) {
            System.err.println("SQLException information");
            System.err.println ("Error msg: " + sqlex.getMessage());
            System.err.println ("SQLSTATE: " + sqlex.getSQLState());
            System.err.println ("Error code: " + sqlex.getErrorCode());
            sqlex.printStackTrace();
            returnCode = 8;
        }

        catch(Exception ex) {
            ex.printStackTrace();
            returnCode = 8;
        }

        return returnCode;
    }

    private String getColumnDefinitions() throws IOException {
        log("Reading column definitions file " + columnDefFileName);
        StringBuffer sb = new StringBuffer();
        BufferedReader in = new BufferedReader(new FileReader(columnDefFileName));
        String line = in.readLine();
        while (line != null) {
            sb.append(line.trim() + " ");
            line = in.readLine();
        }
        return sb.toString();
    }

    private void convertFileToBlockMode() throws IOException {
        log("Converting input file " + inputFileName + " to block mode");
        BufferedReader in = new BufferedReader(new FileReader(inputFileName));
        DataOutputStream dos = new DataOutputStream(new FileOutputStream(blockModeFileName));
        String line = in.readLine();
        line = in.readLine(); // Skip over header line to first line of data
        while (line != null) {
            String curLine = line;
            line = in.readLine();
            byte descriptor = (line != null ? (byte)128 : (byte)64);
            dos.writeByte(descriptor);
            dos.writeShort(curLine.length());
            dos.writeBytes(curLine);
        }
        dos.close();
        in.close();
    }

    private void log(String msg) {
        System.out.println(LocalDateTime.now().toString() + ":  " + msg);
    }
}