import { Card, CardHeader, CardTitle, CardContent } from "../../components/ui/card";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "../../components/ui/tabs";
import { Button } from "../../components/ui/button";
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from "../../components/ui/table";
import { Header } from "../../components/header/Header";

function Dashboard() {
    return (
        <div>
            <Header />
            <div className="p-4">

                <Tabs defaultValue="optionCreator" className="space-y-4">
                    <TabsList>
                        <TabsTrigger value="optionCreator">Option Creator</TabsTrigger>
                        <TabsTrigger value="optionBuyer">Option Buyer</TabsTrigger>
                    </TabsList>

                    <TabsContent value="optionCreator">
                        <Card>
                            <CardHeader>
                                <CardTitle>Total Premium Earned</CardTitle>
                            </CardHeader>
                            <CardContent>
                                <div className="text-2xl font-bold">₹0.00</div>
                            </CardContent>
                        </Card>

                        <div className="mt-4">
                            <Button>Create New Option</Button>
                        </div>

                        <div className="mt-4">
                            <Card>
                                <CardHeader>
                                    <CardTitle>List of Created Options</CardTitle>
                                </CardHeader>
                                <CardContent>
                                    <Table>
                                        <TableHeader>
                                            <TableRow>
                                                <TableHead>Strike Price</TableHead>
                                                <TableHead>Premium</TableHead>
                                                <TableHead>Expiry Date</TableHead>
                                            </TableRow>
                                        </TableHeader>
                                        <TableBody>
                                            <TableRow>
                                                <TableCell>₹0.00</TableCell>
                                                <TableCell>₹0.00</TableCell>
                                                <TableCell>DD/MM/YYYY</TableCell>
                                            </TableRow>
                                        </TableBody>
                                    </Table>
                                </CardContent>
                            </Card>
                        </div>
                    </TabsContent>

                    <TabsContent value="optionBuyer">
                        <Card>
                            <CardHeader>
                                <CardTitle>Purchased Options</CardTitle>
                            </CardHeader>
                            <CardContent>
                                <Table>
                                    <TableHeader>
                                        <TableRow>
                                            <TableHead>Mark Price</TableHead>
                                            <TableHead>Strike Price</TableHead>
                                            <TableHead>Exercise Availability</TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        <TableRow>
                                            <TableCell>₹0.00</TableCell>
                                            <TableCell>₹0.00</TableCell>
                                            <TableCell>DD/MM/YYYY</TableCell>
                                        </TableRow>
                                    </TableBody>
                                </Table>
                            </CardContent>
                        </Card>
                    </TabsContent>
                </Tabs>
            </div>
        </div>

    );
}

export default Dashboard;
