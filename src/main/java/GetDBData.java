import com.ibm.db2.jcc.*;
import java.io.*;
import java.sql.*;
import java.time.*;

public class GetDBData {

    static final String urlPrefix = "jdbc:db2:";

    String outputFileName;
    String url;
    String user;
    String password;
    String schema;

    public static void main(String[] args) {
        if (args.length != 5) {
            System.err.println("This program requires these arguments:");
            System.err.println("  outputFileName database-url user password tablename");
            System.err.println("");
            System.err.println("outputFileName:    output csv file");
            System.err.println("database-url:      database URL in the form //host:port/location");
            System.err.println("user:              userid used to connect to database");
            System.err.println("password:          password used to connect to database");
            System.err.println("schema:            schema which contains patient table");
            System.exit(1);
        }
        String _outputFileName = args[0];
        String _url = urlPrefix + args[1];
        String _user = args[2];
        String _password = args[3];
        String _schema = args[4];
        new GetDBData(_outputFileName, _url, _user, _password, _schema).run();
    }

    public GetDBData(String outputFileName, String url, String user, String password, String schema) {
        this.outputFileName = outputFileName;
        this.url = url;
        this.user = user;
        this.password = password;
        this.schema = schema;
    }

    public void run() {
        Connection con;
        try {
            // Load the driver
            log("Loading the JDBC driver");
            Class.forName("com.ibm.db2.jcc.DB2Driver");

            // Create the connection using the IBM Data Server Driver for JDBC and SQLJ
            log("Creating a JDBC connection to " + url + " with user " + user);
            con = DriverManager.getConnection (url, user, password);

            // Create the Statement
            Statement stmt = con.createStatement();
            
            // Execute a query and generate a ResultSet instance
            log("Querying database");
            ResultSet rs = stmt.executeQuery("SELECT MAX(PATIENTID) FROM " + schema + ".PATIENT"); 
            
            if (!rs.next()) {
                throw new RuntimeException("Empty result set");
            }
            
            Integer lastpatientid = rs.getInt(1);
            log("Last patientid is " + lastpatientid);

            // Close the ResultSet
            rs.close();
            
            // Close the Statement
            stmt.close();

            // Close the connection
            con.close();

            // Write to output file
            DataOutputStream dos = new DataOutputStream(new FileOutputStream(outputFileName));
            dos.writeBytes("LASTPATIENTID\n");
            dos.writeBytes(lastpatientid.toString());
            dos.close();

        }

        catch (ClassNotFoundException e) {
            System.err.println("Could not load JDBC driver");
            System.out.println("Exception: " + e);
            e.printStackTrace();
        }

        catch(SQLException sqlex) {
            System.err.println("SQLException information");
            System.err.println ("Error msg: " + sqlex.getMessage());
            System.err.println ("SQLSTATE: " + sqlex.getSQLState());
            System.err.println ("Error code: " + sqlex.getErrorCode());
            sqlex.printStackTrace();
        }

        catch(Exception ex) {
            ex.printStackTrace();
        }

    }

    private void log(String msg) {
        System.out.println(LocalDateTime.now().toString() + ":  " + msg);
    }
}